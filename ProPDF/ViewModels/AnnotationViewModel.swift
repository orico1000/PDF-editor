import Foundation
import PDFKit
import AppKit

@Observable
class AnnotationViewModel {
    weak var parent: DocumentViewModel?

    // MARK: - Current Tool State

    var currentTool: AnnotationTool = .none
    var strokeColor: NSColor = PDFDefaults.annotationDefaultColor
    var fillColor: NSColor? = nil
    var lineWidth: CGFloat = PDFDefaults.annotationDefaultLineWidth
    var opacity: CGFloat = 1.0
    var fontName: String = PDFDefaults.defaultFontName
    var fontSize: CGFloat = PDFDefaults.defaultFontSize
    var fontColor: NSColor = .black

    // MARK: - Stamp

    var currentStampType: StampType = .approved

    // MARK: - Annotations List

    var annotationModels: [AnnotationModel] = []

    init(parent: DocumentViewModel) {
        self.parent = parent
    }

    private var pdfDocument: PDFDocument? { parent?.pdfDocument }

    // MARK: - Tool Selection

    func selectTool(_ tool: AnnotationTool) {
        currentTool = tool
    }

    func deselectTool() {
        currentTool = .none
    }

    // MARK: - Highlight / Underline / Strikethrough

    func addHighlight(for selection: PDFSelection) {
        guard let doc = pdfDocument else { return }
        let effectiveColor = strokeColor.withAlphaComponent(opacity * 0.5)
        for page in selection.pages {
            guard let selectionForPage = selection.selectionsByLine() as? [PDFSelection] ?? [selection] as [PDFSelection]? else { continue }
            for lineSel in selectionForPage {
                let bounds = lineSel.bounds(for: page)
                guard bounds.width > 0, bounds.height > 0 else { continue }
                let annotation = PDFAnnotation.highlight(bounds: bounds, color: effectiveColor)
                page.addAnnotation(annotation)
            }
            let _ = doc.index(for: page)
        }
        parent?.markDocumentEdited()
        refreshAnnotationModels()
    }

    func addUnderline(for selection: PDFSelection) {
        guard let doc = pdfDocument else { return }
        let effectiveColor = strokeColor.withAlphaComponent(opacity)
        for page in selection.pages {
            let bounds = selection.bounds(for: page)
            guard bounds.width > 0, bounds.height > 0 else { continue }
            let annotation = PDFAnnotation.underline(bounds: bounds, color: effectiveColor)
            page.addAnnotation(annotation)
            let _ = doc.index(for: page)
        }
        parent?.markDocumentEdited()
        refreshAnnotationModels()
    }

    func addStrikethrough(for selection: PDFSelection) {
        guard let doc = pdfDocument else { return }
        let effectiveColor = strokeColor.withAlphaComponent(opacity)
        for page in selection.pages {
            let bounds = selection.bounds(for: page)
            guard bounds.width > 0, bounds.height > 0 else { continue }
            let annotation = PDFAnnotation.strikethrough(bounds: bounds, color: effectiveColor)
            page.addAnnotation(annotation)
            let _ = doc.index(for: page)
        }
        parent?.markDocumentEdited()
        refreshAnnotationModels()
    }

    // MARK: - Sticky Note

    func addStickyNote(at point: CGPoint, on pageIndex: Int, contents: String = "") {
        guard let doc = pdfDocument,
              let page = doc.page(at: pageIndex) else { return }

        let effectiveColor = strokeColor.withAlphaComponent(opacity)
        let annotation = PDFAnnotation.stickyNote(at: point, color: effectiveColor, contents: contents)
        page.addAnnotation(annotation)

        parent?.markDocumentEdited()
        refreshAnnotationModels()
    }

    // MARK: - Free Text

    func addFreeText(at point: CGPoint, on pageIndex: Int, text: String = "Text") {
        guard let doc = pdfDocument,
              let page = doc.page(at: pageIndex) else { return }

        let font = NSFont(name: fontName, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = (text as NSString).size(withAttributes: attrs)
        let padding: CGFloat = 4

        let bounds = CGRect(
            x: point.x,
            y: point.y - textSize.height - padding,
            width: max(textSize.width + padding * 2, 100),
            height: max(textSize.height + padding * 2, 24)
        )

        let annotation = PDFAnnotation.freeText(bounds: bounds, text: text, font: font, color: fontColor)
        if opacity < 1.0 {
            annotation.setValue(opacity, forAnnotationKey: PDFAnnotationKey(rawValue: "/CA"))
        }
        page.addAnnotation(annotation)

        parent?.markDocumentEdited()
        refreshAnnotationModels()
    }

    // MARK: - Shapes

    func addShape(_ tool: AnnotationTool, at bounds: CGRect, on pageIndex: Int) {
        guard let doc = pdfDocument,
              let page = doc.page(at: pageIndex),
              bounds.width > 0, bounds.height > 0 else { return }

        let effectiveStroke = strokeColor.withAlphaComponent(opacity)
        let effectiveFill = fillColor?.withAlphaComponent(opacity)

        let annotation: PDFAnnotation
        switch tool {
        case .rectangle:
            annotation = PDFAnnotation.rectangle(
                bounds: bounds,
                color: effectiveStroke,
                fillColor: effectiveFill,
                lineWidth: lineWidth
            )
        case .oval:
            annotation = PDFAnnotation.oval(
                bounds: bounds,
                color: effectiveStroke,
                fillColor: effectiveFill,
                lineWidth: lineWidth
            )
        case .line:
            annotation = PDFAnnotation.line(
                from: CGPoint(x: bounds.minX, y: bounds.minY),
                to: CGPoint(x: bounds.maxX, y: bounds.maxY),
                color: effectiveStroke,
                lineWidth: lineWidth
            )
        case .arrow:
            let lineAnnotation = PDFAnnotation.line(
                from: CGPoint(x: bounds.minX, y: bounds.minY),
                to: CGPoint(x: bounds.maxX, y: bounds.maxY),
                color: effectiveStroke,
                lineWidth: lineWidth
            )
            lineAnnotation.endLineStyle = .openArrow
            annotation = lineAnnotation
        default:
            return
        }

        page.addAnnotation(annotation)
        parent?.markDocumentEdited()
        refreshAnnotationModels()
    }

    // MARK: - Stamp

    func addStamp(_ stampType: StampType, at point: CGPoint, on pageIndex: Int) {
        guard let doc = pdfDocument,
              let page = doc.page(at: pageIndex) else { return }

        let stampWidth: CGFloat = 200
        let stampHeight: CGFloat = 60
        let bounds = CGRect(
            x: point.x - stampWidth / 2,
            y: point.y - stampHeight / 2,
            width: stampWidth,
            height: stampHeight
        )

        let annotation = PDFAnnotation.stamp(bounds: bounds, type: stampType)
        page.addAnnotation(annotation)

        parent?.markDocumentEdited()
        refreshAnnotationModels()
    }

    // MARK: - Freehand / Ink

    func addFreehandStroke(_ points: [[CGPoint]], on pageIndex: Int) {
        guard let doc = pdfDocument,
              let page = doc.page(at: pageIndex),
              !points.isEmpty else { return }

        let effectiveColor = strokeColor.withAlphaComponent(opacity)
        let annotation = PDFAnnotation.ink(paths: points, color: effectiveColor, lineWidth: lineWidth)
        page.addAnnotation(annotation)

        parent?.markDocumentEdited()
        refreshAnnotationModels()
    }

    // MARK: - Link

    func addLink(bounds: CGRect, url: URL, on pageIndex: Int) {
        guard let doc = pdfDocument,
              let page = doc.page(at: pageIndex),
              let annotation = PDFAnnotation.link(bounds: bounds, url: url) else { return }

        page.addAnnotation(annotation)

        parent?.markDocumentEdited()
        refreshAnnotationModels()
    }

    func addLink(bounds: CGRect, destinationPageIndex: Int, on pageIndex: Int) {
        guard let doc = pdfDocument,
              let page = doc.page(at: pageIndex),
              let destPage = doc.page(at: destinationPageIndex) else { return }

        let destination = PDFDestination(page: destPage, at: .zero)
        let annotation = PDFAnnotation.link(bounds: bounds, destination: destination)
        page.addAnnotation(annotation)

        parent?.markDocumentEdited()
        refreshAnnotationModels()
    }

    // MARK: - Delete / Update

    func deleteAnnotation(_ annotation: PDFAnnotation) {
        guard let page = annotation.page else { return }
        page.removeAnnotation(annotation)
        parent?.state.selectedAnnotation = nil
        parent?.markDocumentEdited()
        refreshAnnotationModels()
    }

    func updateAnnotation(_ annotation: PDFAnnotation, properties: AnnotationModel) {
        properties.apply(to: annotation)
        parent?.markDocumentEdited()
        refreshAnnotationModels()
    }

    func selectAnnotation(_ annotation: PDFAnnotation?) {
        parent?.state.selectedAnnotation = annotation
    }

    // MARK: - Annotations Model List

    func refreshAnnotationModels() {
        guard let doc = pdfDocument else {
            annotationModels = []
            return
        }

        var models: [AnnotationModel] = []
        for i in 0..<doc.pageCount {
            guard let page = doc.page(at: i) else { continue }
            for annotation in page.annotations {
                // Skip widget (form field) annotations
                if annotation.type == "Widget" { continue }
                models.append(AnnotationModel(from: annotation, pageIndex: i))
            }
        }
        annotationModels = models
    }

    func annotation(at pageIndex: Int, bounds: CGRect) -> PDFAnnotation? {
        guard let doc = pdfDocument,
              let page = doc.page(at: pageIndex) else { return nil }
        return page.annotation(at: CGPoint(x: bounds.midX, y: bounds.midY))
    }

    // MARK: - Flatten All Annotations

    func flattenAll() {
        guard let doc = pdfDocument else { return }
        doc.flattenAnnotations()
        parent?.markDocumentEdited()
        refreshAnnotationModels()
    }
}
