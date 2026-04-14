import Cocoa
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

class ProPDFDocument: NSDocument {
    var pdfDocument: PDFDocument?
    var documentViewModel: DocumentViewModel!
    private var passwordForSaving: String?

    override init() {
        super.init()
        documentViewModel = DocumentViewModel(document: self)
    }

    override class var autosavesInPlace: Bool { true }

    override func canAsynchronouslyWrite(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) -> Bool {
        true
    }

    // MARK: - Reading

    override func read(from url: URL, ofType typeName: String) throws {
        guard let document = PDFDocument(url: url) else {
            throw ProPDFError.invalidPDF
        }

        if document.isLocked {
            // Store the document; we'll prompt for password in the UI
            self.pdfDocument = document
            return
        }

        self.pdfDocument = document
        documentViewModel = DocumentViewModel(document: self)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        guard let document = PDFDocument(data: data) else {
            throw ProPDFError.invalidPDF
        }

        self.pdfDocument = document
        documentViewModel = DocumentViewModel(document: self)
    }

    // MARK: - Writing

    override func data(ofType typeName: String) throws -> Data {
        guard let pdfDocument else {
            throw ProPDFError.invalidPDF
        }

        let security = documentViewModel.security.settings
        if security.needsEncryption {
            // Rewrite with encryption via CGPDFContext
            let tempURL = FileCoordination.temporaryURL()
            defer { try? FileManager.default.removeItem(at: tempURL) }
            try PDFRewriter.rewriteWithSecurity(pdfDocument, to: tempURL, settings: security)
            guard let data = try? Data(contentsOf: tempURL) else {
                throw ProPDFError.encryptionFailed("Failed to read encrypted PDF")
            }
            return data
        }

        guard let data = pdfDocument.dataRepresentation() else {
            throw ProPDFError.fileWriteFailed(fileURL ?? URL(fileURLWithPath: "unknown"), underlying: nil)
        }
        return data
    }

    // MARK: - Window

    override func makeWindowControllers() {
        let contentView = ContentView(viewModel: documentViewModel)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        let hostingController = NSHostingController(rootView: contentView)

        let screen = NSScreen.main ?? NSScreen.screens.first
        let screenFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let windowWidth = screenFrame.width * 0.85
        let windowHeight = screenFrame.height * 0.9

        let window = NSWindow(
            contentRect: NSRect(
                x: screenFrame.origin.x + (screenFrame.width - windowWidth) / 2,
                y: screenFrame.origin.y + (screenFrame.height - windowHeight) / 2,
                width: windowWidth,
                height: windowHeight
            ),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingController
        window.titleVisibility = .visible
        window.toolbarStyle = .unified
        window.tabbingMode = .preferred
        window.minSize = NSSize(width: 600, height: 400)
        window.title = fileURL?.lastPathComponent ?? "Untitled"

        let windowController = NSWindowController(window: window)
        windowController.contentViewController = hostingController
        addWindowController(windowController)
    }

    // MARK: - Password

    func unlock(with password: String) -> Bool {
        guard let pdfDocument, pdfDocument.isLocked else { return true }
        let success = pdfDocument.unlock(withPassword: password)
        if success {
            passwordForSaving = password
            documentViewModel = DocumentViewModel(document: self)
        }
        return success
    }

    // MARK: - Printing

    override func printDocument(_ sender: Any?) {
        guard let pdfDocument else { return }
        guard let printInfo = NSPrintInfo.shared.copy() as? NSPrintInfo else { return }
        printInfo.isHorizontallyCentered = true
        printInfo.isVerticallyCentered = true

        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        pdfView.frame = NSRect(x: 0, y: 0, width: 612, height: 792)

        let printOperation = NSPrintOperation(view: pdfView, printInfo: printInfo)
        printOperation.showsPrintPanel = true
        printOperation.showsProgressPanel = true
        runModalPrintOperation(printOperation, delegate: nil, didRun: nil, contextInfo: nil)
    }

    // MARK: - Document types

    override class var readableTypes: [String] {
        [UTType.pdf.identifier]
    }

    override class var writableTypes: [String] {
        [UTType.pdf.identifier]
    }

    override class func isNativeType(_ type: String) -> Bool {
        type == UTType.pdf.identifier
    }
}
