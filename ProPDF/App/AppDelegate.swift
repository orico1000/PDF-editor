import Cocoa
import PDFKit
import UniformTypeIdentifiers

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

    // MARK: - File Actions

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

    @objc func saveDocument(_ sender: Any?) {
        currentDocument?.save(sender)
    }

    @objc func saveDocumentAs(_ sender: Any?) {
        currentDocument?.saveAs(sender)
    }

    @objc func revertDocument(_ sender: Any?) {
        currentDocument?.revertToSaved(sender)
    }

    @objc func printDocument(_ sender: Any?) {
        currentDocument?.printDocument(sender)
    }

    @objc func closeDocument(_ sender: Any?) {
        NSApp.keyWindow?.close()
    }

    @objc func exportAsImages(_ sender: Any?) {
        NotificationCenter.default.post(name: .documentAction, object: DocumentAction.exportImages)
    }

    @objc func exportAsText(_ sender: Any?) {
        guard let doc = currentDocument, let pdfDoc = doc.pdfDocument else { return }
        let text = pdfDoc.allPages.compactMap { $0.string }.joined(separator: "\n\n")

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = (doc.fileURL?.deletingPathExtension().lastPathComponent ?? "document") + ".txt"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? text.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    @objc func mergeDocuments(_ sender: Any?) {
        NotificationCenter.default.post(name: .documentAction, object: DocumentAction.mergeDocuments)
    }

    @objc func createFromImages(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.jpeg, .png, .tiff, .bmp, .heic]
        panel.message = "Select images to combine into a PDF"
        panel.begin { response in
            guard response == .OK, !panel.urls.isEmpty else { return }

            let doc = ProPDFDocument()
            let newPDF = PDFDocument()

            for url in panel.urls {
                guard let image = NSImage(contentsOf: url),
                      let page = image.toPDFPage() else { continue }
                newPDF.insert(page, at: newPDF.pageCount)
            }

            guard newPDF.pageCount > 0 else { return }

            doc.pdfDocument = newPDF
            doc.documentViewModel = DocumentViewModel(document: doc)
            doc.makeWindowControllers()
            doc.showWindows()
            NSDocumentController.shared.addDocument(doc)
        }
    }

    // MARK: - Menu Action Dispatch

    @objc private func menuAction(_ sender: NSMenuItem) {
        guard let actionName = sender.representedObject as? String,
              let action = DocumentAction(rawValue: actionName) else { return }
        NotificationCenter.default.post(name: .documentAction, object: action)
    }

    // MARK: - Helpers

    private var currentDocument: ProPDFDocument? {
        NSDocumentController.shared.currentDocument as? ProPDFDocument
    }

    // MARK: - Menu Setup

    private func setupMainMenu() {
        let mainMenu = NSApp.mainMenu ?? NSMenu()

        // Insert File menu at position 1 (after the app menu)
        let fileMenu = NSMenu(title: "File")

        let newItem = NSMenuItem(title: "New Blank PDF", action: #selector(newBlankDocument(_:)), keyEquivalent: "n")
        newItem.target = self
        fileMenu.addItem(newItem)

        let createFromImagesItem = NSMenuItem(title: "New from Images...", action: #selector(createFromImages(_:)), keyEquivalent: "")
        createFromImagesItem.target = self
        fileMenu.addItem(createFromImagesItem)

        fileMenu.addItem(.separator())

        let openItem = NSMenuItem(title: "Open...", action: #selector(openDocument(_:)), keyEquivalent: "o")
        openItem.target = self
        fileMenu.addItem(openItem)

        // Open Recent submenu
        let openRecentMenu = NSMenu(title: "Open Recent")
        let clearRecentItem = NSMenuItem(title: "Clear Menu", action: #selector(NSDocumentController.clearRecentDocuments(_:)), keyEquivalent: "")
        openRecentMenu.addItem(clearRecentItem)
        let openRecentItem = NSMenuItem(title: "Open Recent", action: nil, keyEquivalent: "")
        openRecentItem.submenu = openRecentMenu
        fileMenu.addItem(openRecentItem)
        documentController.standardOpenRecentMenu = openRecentMenu

        fileMenu.addItem(.separator())

        let closeItem = NSMenuItem(title: "Close", action: #selector(closeDocument(_:)), keyEquivalent: "w")
        closeItem.target = self
        fileMenu.addItem(closeItem)

        let saveItem = NSMenuItem(title: "Save", action: #selector(saveDocument(_:)), keyEquivalent: "s")
        saveItem.target = self
        fileMenu.addItem(saveItem)

        let saveAsItem = NSMenuItem(title: "Save As...", action: #selector(saveDocumentAs(_:)), keyEquivalent: "S")
        saveAsItem.target = self
        fileMenu.addItem(saveAsItem)

        let revertItem = NSMenuItem(title: "Revert to Saved", action: #selector(revertDocument(_:)), keyEquivalent: "")
        revertItem.target = self
        fileMenu.addItem(revertItem)

        fileMenu.addItem(.separator())

        // Export submenu
        let exportMenu = NSMenu(title: "Export As")

        let exportImagesItem = NSMenuItem(title: "Images (JPEG, PNG, TIFF)...", action: #selector(exportAsImages(_:)), keyEquivalent: "e")
        exportImagesItem.keyEquivalentModifierMask = [.command, .shift]
        exportImagesItem.target = self
        exportMenu.addItem(exportImagesItem)

        let exportTextItem = NSMenuItem(title: "Plain Text...", action: #selector(exportAsText(_:)), keyEquivalent: "")
        exportTextItem.target = self
        exportMenu.addItem(exportTextItem)

        let exportSubmenuItem = NSMenuItem(title: "Export As", action: nil, keyEquivalent: "")
        exportSubmenuItem.submenu = exportMenu
        fileMenu.addItem(exportSubmenuItem)

        fileMenu.addItem(.separator())

        let mergeItem = NSMenuItem(title: "Merge Documents...", action: #selector(mergeDocuments(_:)), keyEquivalent: "")
        mergeItem.target = self
        fileMenu.addItem(mergeItem)

        fileMenu.addItem(.separator())

        let printItem = NSMenuItem(title: "Print...", action: #selector(printDocument(_:)), keyEquivalent: "p")
        printItem.target = self
        fileMenu.addItem(printItem)

        let fileMenuItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        fileMenuItem.submenu = fileMenu
        mainMenu.insertItem(fileMenuItem, at: 1)

        // Edit menu at position 2
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z"))
        editMenu.addItem(.separator())
        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenu.addItem(.separator())

        let findItem = NSMenuItem(title: "Find in Document...", action: #selector(menuAction(_:)), keyEquivalent: "f")
        findItem.representedObject = DocumentAction.find.rawValue
        findItem.target = self
        editMenu.addItem(findItem)

        let editMenuItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        editMenuItem.submenu = editMenu
        mainMenu.insertItem(editMenuItem, at: 2)

        // View menu at position 3
        let viewMenu = NSMenu(title: "View")
        viewMenu.addItem(menuItem("Toggle Sidebar", action: .toggleSidebar, key: "s", modifiers: [.command, .option]))
        viewMenu.addItem(menuItem("Toggle Inspector", action: .toggleInspector, key: "i", modifiers: [.command, .option]))
        viewMenu.addItem(.separator())
        viewMenu.addItem(menuItem("Zoom In", action: .zoomIn, key: "+"))
        viewMenu.addItem(menuItem("Zoom Out", action: .zoomOut, key: "-"))
        viewMenu.addItem(menuItem("Zoom to Fit", action: .zoomToFit, key: "0"))
        viewMenu.addItem(.separator())
        viewMenu.addItem(menuItem("Single Page", action: .displaySingle))
        viewMenu.addItem(menuItem("Single Page Continuous", action: .displaySingleContinuous))
        viewMenu.addItem(menuItem("Two Pages", action: .displayTwoUp))
        viewMenu.addItem(menuItem("Two Pages Continuous", action: .displayTwoUpContinuous))

        let viewMenuItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        viewMenuItem.submenu = viewMenu
        mainMenu.insertItem(viewMenuItem, at: 3)

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

// MARK: - Open Recent support

extension PDFDocumentController {
    var standardOpenRecentMenu: NSMenu? {
        get { value(forKey: "_recentDocumentsMenu") as? NSMenu }
        set { setValue(newValue, forKey: "_recentDocumentsMenu") }
    }
}
