import Cocoa
import PDFKit

class AppDelegate: NSObject, NSApplicationDelegate {
    let documentController = PDFDocumentController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = true
        setupMainMenu()

        // Show Open dialog on first launch if no documents restored
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if NSApp.windows.filter({ $0.isVisible }).isEmpty {
                self.openDocument(nil)
            }
        }
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - Actions

    @objc func newBlankDocument(_ sender: Any?) {
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

    @objc func openDocument(_ sender: Any?) {
        NSDocumentController.shared.openDocument(sender)
    }

    @objc private func menuAction(_ sender: NSMenuItem) {
        guard let actionName = sender.representedObject as? String,
              let action = DocumentAction(rawValue: actionName) else { return }
        NotificationCenter.default.post(name: .documentAction, object: action)
    }

    // MARK: - Menu Setup

    private func setupMainMenu() {
        let mainMenu = NSApp.mainMenu ?? NSMenu()

        // Tools menu
        let toolsMenu = NSMenu(title: "Tools")
        toolsMenu.addItem(menuItem("Run OCR", action: .runOCR, key: "r", modifiers: [.command, .shift]))
        toolsMenu.addItem(menuItem("Compare Documents...", action: .compareDocuments))
        toolsMenu.addItem(menuItem("Compress PDF...", action: .compress))
        toolsMenu.addItem(.separator())
        toolsMenu.addItem(menuItem("Add Watermark...", action: .addWatermark))
        toolsMenu.addItem(menuItem("Add Header/Footer...", action: .addHeaderFooter))
        toolsMenu.addItem(.separator())
        toolsMenu.addItem(menuItem("Password & Security...", action: .security))
        toolsMenu.addItem(menuItem("Redact Content...", action: .redact))
        toolsMenu.addItem(.separator())
        toolsMenu.addItem(menuItem("Accessibility Check...", action: .accessibilityCheck))

        let toolsMenuItem = NSMenuItem(title: "Tools", action: nil, keyEquivalent: "")
        toolsMenuItem.submenu = toolsMenu
        mainMenu.addItem(toolsMenuItem)

        // Pages menu
        let pagesMenu = NSMenu(title: "Pages")
        pagesMenu.addItem(menuItem("Insert Blank Page", action: .insertBlankPage, key: "n", modifiers: [.command, .shift]))
        pagesMenu.addItem(menuItem("Delete Page", action: .deletePage))
        pagesMenu.addItem(.separator())
        pagesMenu.addItem(menuItem("Rotate Clockwise", action: .rotateRight, key: "]", modifiers: [.command]))
        pagesMenu.addItem(menuItem("Rotate Counter-Clockwise", action: .rotateLeft, key: "[", modifiers: [.command]))
        pagesMenu.addItem(.separator())
        pagesMenu.addItem(menuItem("Extract Pages...", action: .extractPages))
        pagesMenu.addItem(menuItem("Split Document...", action: .splitDocument))

        let pagesMenuItem = NSMenuItem(title: "Pages", action: nil, keyEquivalent: "")
        pagesMenuItem.submenu = pagesMenu
        mainMenu.addItem(pagesMenuItem)

        // Forms menu
        let formsMenu = NSMenu(title: "Forms")
        formsMenu.addItem(menuItem("Create Form Fields", action: .createForms))
        formsMenu.addItem(menuItem("Auto-Detect Fields", action: .autoDetectFields))
        formsMenu.addItem(.separator())
        formsMenu.addItem(menuItem("Fill & Sign", action: .fillSign))
        formsMenu.addItem(menuItem("Digital Signature...", action: .digitalSign))

        let formsMenuItem = NSMenuItem(title: "Forms", action: nil, keyEquivalent: "")
        formsMenuItem.submenu = formsMenu
        mainMenu.addItem(formsMenuItem)
    }

    private func menuItem(_ title: String, action: DocumentAction, key: String = "", modifiers: NSEvent.ModifierFlags = []) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(menuAction(_:)), keyEquivalent: key)
        item.keyEquivalentModifierMask = modifiers
        item.representedObject = action.rawValue
        item.target = self
        return item
    }
}
