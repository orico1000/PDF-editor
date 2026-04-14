import SwiftUI
import PDFKit
import UniformTypeIdentifiers

@main
struct ProPDFApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Use Settings scene as a placeholder — actual document windows
        // are managed by NSDocumentController / ProPDFDocument
        Settings {
            Text("ProPDF Preferences")
                .frame(width: 400, height: 300)
        }

        Window("Batch Processing", id: "batch") {
            BatchProcessingWindow()
        }
        .defaultSize(width: 800, height: 600)
    }
}

enum DocumentAction: String {
    case toggleSidebar, toggleInspector
    case zoomIn, zoomOut, zoomToFit
    case displaySingle, displaySingleContinuous, displayTwoUp, displayTwoUpContinuous
    case find
    case runOCR, compareDocuments, compress
    case addWatermark, addHeaderFooter
    case security, redact
    case accessibilityCheck
    case insertBlankPage, deletePage
    case rotateRight, rotateLeft
    case extractPages, splitDocument
    case mergeDocuments
    case exportImages
    case createForms, autoDetectFields
    case fillSign, digitalSign
}

extension Notification.Name {
    static let documentAction = Notification.Name("ProPDFDocumentAction")
}
