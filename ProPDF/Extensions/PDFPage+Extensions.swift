import PDFKit
import AppKit
import CoreGraphics

extension PDFPage {
    var pageSize: CGSize {
        bounds(for: .mediaBox).size
    }

    func renderToImage(dpi: CGFloat = 150) -> NSImage? {
        let pageRect = bounds(for: .mediaBox)
        let scale = dpi / 72.0
        let width = pageRect.width * scale
        let height = pageRect.height * scale
        let imageSize = CGSize(width: width, height: height)

        let image = NSImage(size: imageSize)
        image.lockFocus()

        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }

        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: imageSize))
        context.scaleBy(x: scale, y: scale)

        draw(with: .mediaBox, to: context)

        image.unlockFocus()
        return image
    }

    func renderToCGImage(dpi: CGFloat = 150) -> CGImage? {
        let pageRect = bounds(for: .mediaBox)
        let scale = dpi / 72.0
        let width = Int(pageRect.width * scale)
        let height = Int(pageRect.height * scale)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.scaleBy(x: scale, y: scale)

        draw(with: .mediaBox, to: context)

        return context.makeImage()
    }

    func thumbnail(maxDimension: CGFloat = 160) -> NSImage {
        let pageRect = bounds(for: .mediaBox)
        let scale = min(maxDimension / pageRect.width, maxDimension / pageRect.height)
        let thumbSize = CGSize(
            width: pageRect.width * scale,
            height: pageRect.height * scale
        )
        return thumbnail(of: thumbSize, for: .mediaBox)
    }

    func annotationsOfType(_ type: String) -> [PDFAnnotation] {
        annotations.filter { $0.type == type }
    }

    func removeAllAnnotations() {
        let toRemove = annotations
        for annotation in toRemove {
            removeAnnotation(annotation)
        }
    }

    var hasText: Bool {
        !(string ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func blankPage(size: CGSize = PDFDefaults.defaultPageSize) -> PDFPage {
        let data = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: size)
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return PDFPage()
        }
        context.beginPDFPage(nil)
        context.endPDFPage()
        context.closePDF()
        guard let provider = CGDataProvider(data: data as CFData),
              let cgDoc = CGPDFDocument(provider),
              let cgPage = cgDoc.page(at: 1) else {
            return PDFPage()
        }
        guard let blankDoc = PDFDocument(data: data as Data),
              let blankPage = blankDoc.page(at: 0) else {
            return PDFPage()
        }
        return blankPage
    }
}
