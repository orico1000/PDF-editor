import SwiftUI
import PDFKit

struct PDFViewerRepresentable: NSViewRepresentable {
    let viewModel: DocumentViewModel

    func makeCoordinator() -> PDFViewCoordinator {
        PDFViewCoordinator(viewModel: viewModel)
    }

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displaysPageBreaks = true
        pdfView.displayDirection = .vertical
        pdfView.pageShadowsEnabled = true
        pdfView.backgroundColor = NSColor.controlBackgroundColor
        pdfView.delegate = context.coordinator

        pdfView.document = viewModel.pdfDocument
        pdfView.displayMode = viewModel.state.displayMode

        context.coordinator.setupObservers(for: pdfView)

        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        context.coordinator.viewModel = viewModel

        // Update document if changed
        if pdfView.document !== viewModel.pdfDocument {
            pdfView.document = viewModel.pdfDocument
            context.coordinator.setupObservers(for: pdfView)
        }

        // Update display mode
        if pdfView.displayMode != viewModel.state.displayMode {
            pdfView.displayMode = viewModel.state.displayMode
        }

        // Update zoom
        let targetZoom = viewModel.state.zoomLevel
        if abs(pdfView.scaleFactor - targetZoom) > 0.001 {
            pdfView.scaleFactor = targetZoom
        }

        // Navigate to page
        let targetPage = viewModel.state.currentPageIndex
        if let doc = pdfView.document,
           let currentPage = pdfView.currentPage {
            let currentIndex = doc.index(for: currentPage)
            if currentIndex != targetPage,
               let page = doc.page(at: targetPage) {
                pdfView.go(to: page)
            }
        }

        // Highlight current search selection
        if let selection = viewModel.viewer.currentSelection {
            pdfView.setCurrentSelection(selection, animate: true)
            if let page = selection.pages.first {
                pdfView.go(to: selection.bounds(for: page), on: page)
            }
        }
    }
}
