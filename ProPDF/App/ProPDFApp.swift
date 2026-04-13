import SwiftUI
import PDFKit
import UniformTypeIdentifiers

@main
struct ProPDFApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        DocumentGroup(viewing: PDFReferenceDocument.self) { config in
            if let doc = NSDocumentController.shared.currentDocument as? ProPDFDocument {
                ContentView(viewModel: doc.documentViewModel)
            } else {
                Text("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .commands {
            appMenuCommands
        }

        Window("Batch Processing", id: "batch") {
            BatchProcessingWindow()
        }
        .defaultSize(width: 800, height: 600)
    }

    @CommandsBuilder
    var appMenuCommands: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Blank PDF") {
                createNewBlankPDF()
            }
            .keyboardShortcut("n")

            Divider()

            Button("Open...") {
                NSDocumentController.shared.openDocument(nil)
            }
            .keyboardShortcut("o")
        }

        CommandGroup(after: .importExport) {
            Button("Export as Images...") {
                notifyFocusedDocument(action: .exportImages)
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])

            Button("Merge Documents...") {
                notifyFocusedDocument(action: .mergeDocuments)
            }
        }

        CommandGroup(replacing: .toolbar) {
            Button("Toggle Sidebar") {
                notifyFocusedDocument(action: .toggleSidebar)
            }
            .keyboardShortcut("s", modifiers: [.command, .option])

            Button("Toggle Inspector") {
                notifyFocusedDocument(action: .toggleInspector)
            }
            .keyboardShortcut("i", modifiers: [.command, .option])

            Divider()

            Button("Zoom In") {
                notifyFocusedDocument(action: .zoomIn)
            }
            .keyboardShortcut("+")

            Button("Zoom Out") {
                notifyFocusedDocument(action: .zoomOut)
            }
            .keyboardShortcut("-")

            Button("Zoom to Fit") {
                notifyFocusedDocument(action: .zoomToFit)
            }
            .keyboardShortcut("0")

            Divider()

            Menu("Display Mode") {
                Button("Single Page") { notifyFocusedDocument(action: .displaySingle) }
                Button("Single Page Continuous") { notifyFocusedDocument(action: .displaySingleContinuous) }
                Button("Two Pages") { notifyFocusedDocument(action: .displayTwoUp) }
                Button("Two Pages Continuous") { notifyFocusedDocument(action: .displayTwoUpContinuous) }
            }
        }

        CommandGroup(after: .textEditing) {
            Divider()
            Button("Find in Document...") {
                notifyFocusedDocument(action: .find)
            }
            .keyboardShortcut("f")
        }

        CommandMenu("Tools") {
            Button("Run OCR...") {
                notifyFocusedDocument(action: .runOCR)
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])

            Button("Compare Documents...") {
                notifyFocusedDocument(action: .compareDocuments)
            }

            Button("Compress PDF...") {
                notifyFocusedDocument(action: .compress)
            }

            Divider()

            Button("Add Watermark...") {
                notifyFocusedDocument(action: .addWatermark)
            }

            Button("Add Header/Footer...") {
                notifyFocusedDocument(action: .addHeaderFooter)
            }

            Divider()

            Button("Password & Security...") {
                notifyFocusedDocument(action: .security)
            }

            Button("Redact Content...") {
                notifyFocusedDocument(action: .redact)
            }

            Divider()

            Button("Accessibility Check...") {
                notifyFocusedDocument(action: .accessibilityCheck)
            }
        }

        CommandMenu("Pages") {
            Button("Insert Blank Page") {
                notifyFocusedDocument(action: .insertBlankPage)
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])

            Button("Delete Page") {
                notifyFocusedDocument(action: .deletePage)
            }

            Divider()

            Button("Rotate Clockwise") {
                notifyFocusedDocument(action: .rotateRight)
            }
            .keyboardShortcut("]", modifiers: [.command])

            Button("Rotate Counter-Clockwise") {
                notifyFocusedDocument(action: .rotateLeft)
            }
            .keyboardShortcut("[", modifiers: [.command])

            Divider()

            Button("Extract Pages...") {
                notifyFocusedDocument(action: .extractPages)
            }

            Button("Split Document...") {
                notifyFocusedDocument(action: .splitDocument)
            }
        }

        CommandMenu("Forms") {
            Button("Create Form Fields") {
                notifyFocusedDocument(action: .createForms)
            }

            Button("Auto-Detect Fields") {
                notifyFocusedDocument(action: .autoDetectFields)
            }

            Divider()

            Button("Fill & Sign") {
                notifyFocusedDocument(action: .fillSign)
            }

            Button("Digital Signature...") {
                notifyFocusedDocument(action: .digitalSign)
            }
        }
    }

    private func createNewBlankPDF() {
        let doc = ProPDFDocument()
        let newPDF = PDFDocument()
        let blankPage = PDFPage.blankPage()
        newPDF.insert(blankPage, at: 0)
        doc.pdfDocument = newPDF
        doc.documentViewModel = DocumentViewModel(document: doc)
        doc.makeWindowControllers()
        doc.showWindows()
        NSDocumentController.shared.addDocument(doc)
    }

    private func notifyFocusedDocument(action: DocumentAction) {
        NotificationCenter.default.post(name: .documentAction, object: action)
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

// Minimal FileDocument wrapper for DocumentGroup compatibility
struct PDFReferenceDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }

    init(configuration: ReadConfiguration) throws {
        // Actual loading is handled by ProPDFDocument
    }

    init() {}

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data())
    }
}
