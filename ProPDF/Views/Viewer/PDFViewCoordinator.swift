import Foundation
import PDFKit
import AppKit
import Combine

class PDFViewCoordinator: NSObject, PDFViewDelegate {
    var viewModel: DocumentViewModel
    private var pageChangeObserver: Any?
    private var scaleChangeObserver: Any?
    private var selectionChangeObserver: Any?
    private var annotationHitObserver: Any?

    init(viewModel: DocumentViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    func setupObservers(for pdfView: PDFView) {
        removeObservers()

        let center = NotificationCenter.default

        pageChangeObserver = center.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let doc = pdfView.document else { return }
            let index = doc.index(for: currentPage)
            if self.viewModel.state.currentPageIndex != index {
                self.viewModel.state.currentPageIndex = index
            }
        }

        scaleChangeObserver = center.addObserver(
            forName: .PDFViewScaleChanged,
            object: pdfView,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let pdfView = notification.object as? PDFView else { return }
            let newZoom = pdfView.scaleFactor
            if abs(self.viewModel.state.zoomLevel - newZoom) > 0.001 {
                self.viewModel.state.zoomLevel = newZoom
            }
        }

        selectionChangeObserver = center.addObserver(
            forName: .PDFViewSelectionChanged,
            object: pdfView,
            queue: .main
        ) { [weak self] _ in
            // Selection changed - can be used for text editing tools
            _ = self
        }

        annotationHitObserver = center.addObserver(
            forName: .PDFViewAnnotationHit,
            object: pdfView,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let annotation = notification.userInfo?["PDFAnnotationHit"] as? PDFAnnotation else { return }
            self.viewModel.state.selectedAnnotation = annotation
        }
    }

    func removeObservers() {
        let center = NotificationCenter.default
        if let obs = pageChangeObserver { center.removeObserver(obs) }
        if let obs = scaleChangeObserver { center.removeObserver(obs) }
        if let obs = selectionChangeObserver { center.removeObserver(obs) }
        if let obs = annotationHitObserver { center.removeObserver(obs) }
        pageChangeObserver = nil
        scaleChangeObserver = nil
        selectionChangeObserver = nil
        annotationHitObserver = nil
    }

    deinit {
        removeObservers()
    }

    // MARK: - PDFViewDelegate

    func pdfViewWillClick(onLink sender: PDFView, with url: URL) {
        // Security: only allow safe URL schemes to prevent protocol handler abuse
        let allowedSchemes: Set<String> = ["http", "https", "mailto"]
        guard let scheme = url.scheme?.lowercased(), allowedSchemes.contains(scheme) else {
            // Block file://, ssh://, applescript://, and other potentially dangerous schemes
            return
        }
        NSWorkspace.shared.open(url)
    }
}
