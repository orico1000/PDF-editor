import Cocoa
import PDFKit
import UniformTypeIdentifiers

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    let documentController = PDFDocumentController()

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Build menu BEFORE windows appear so it's visible from the start
        buildEntireMainMenu()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = true

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

    // MARK: - Complete Menu Bar

    private func buildEntireMainMenu() {
        let mainMenu = NSMenu()

        // ── App menu ──
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "About ProPDF", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Settings...", action: Selector(("showSettingsWindow:")), keyEquivalent: ","))
        appMenu.addItem(.separator())
        let servicesMenu = NSMenu(title: "Services")
        let servicesItem = NSMenuItem(title: "Services", action: nil, keyEquivalent: "")
        servicesItem.submenu = servicesMenu
        appMenu.addItem(servicesItem)
        NSApp.servicesMenu = servicesMenu
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Hide ProPDF", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        let hideOthersItem = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthersItem)
        appMenu.addItem(NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Quit ProPDF", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // ── File menu ──
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

        // Open Recent
        let openRecentMenu = NSMenu(title: "Open Recent")
        let clearRecentItem = NSMenuItem(title: "Clear Menu", action: #selector(NSDocumentController.clearRecentDocuments(_:)), keyEquivalent: "")
        openRecentMenu.addItem(clearRecentItem)
        let openRecentItem = NSMenuItem(title: "Open Recent", action: nil, keyEquivalent: "")
        openRecentItem.submenu = openRecentMenu
        fileMenu.addItem(openRecentItem)

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

        // Export As submenu
        let exportMenu = NSMenu(title: "Export As")
        let expImgItem = NSMenuItem(title: "Images (JPEG, PNG, TIFF)...", action: #selector(exportAsImages(_:)), keyEquivalent: "e")
        expImgItem.keyEquivalentModifierMask = [.command, .shift]
        expImgItem.target = self
        exportMenu.addItem(expImgItem)
        let expTxtItem = NSMenuItem(title: "Plain Text...", action: #selector(exportAsText(_:)), keyEquivalent: "")
        expTxtItem.target = self
        exportMenu.addItem(expTxtItem)
        let exportSubItem = NSMenuItem(title: "Export As", action: nil, keyEquivalent: "")
        exportSubItem.submenu = exportMenu
        fileMenu.addItem(exportSubItem)

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
        mainMenu.addItem(fileMenuItem)

        // ── Edit menu ──
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z"))
        editMenu.addItem(.separator())
        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenu.addItem(.separator())
        let findItem = actionMenuItem("Find in Document...", action: .find, key: "f")
        editMenu.addItem(findItem)

        let editMenuItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // ── View menu ──
        let viewMenu = NSMenu(title: "View")
        viewMenu.addItem(actionMenuItem("Toggle Sidebar", action: .toggleSidebar, key: "s", modifiers: [.command, .option]))
        viewMenu.addItem(actionMenuItem("Toggle Inspector", action: .toggleInspector, key: "i", modifiers: [.command, .option]))
        viewMenu.addItem(.separator())
        viewMenu.addItem(actionMenuItem("Zoom In", action: .zoomIn, key: "+"))
        viewMenu.addItem(actionMenuItem("Zoom Out", action: .zoomOut, key: "-"))
        viewMenu.addItem(actionMenuItem("Zoom to Fit", action: .zoomToFit, key: "0"))
        viewMenu.addItem(.separator())
        viewMenu.addItem(actionMenuItem("Single Page", action: .displaySingle))
        viewMenu.addItem(actionMenuItem("Single Page Continuous", action: .displaySingleContinuous))
        viewMenu.addItem(actionMenuItem("Two Pages", action: .displayTwoUp))
        viewMenu.addItem(actionMenuItem("Two Pages Continuous", action: .displayTwoUpContinuous))

        let viewMenuItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        // ── Tools menu ──
        let toolsMenu = NSMenu(title: "Tools")
        toolsMenu.addItem(actionMenuItem("Run OCR", action: .runOCR, key: "r", modifiers: [.command, .shift]))
        toolsMenu.addItem(actionMenuItem("Compare Documents...", action: .compareDocuments))
        toolsMenu.addItem(actionMenuItem("Compress PDF...", action: .compress))
        toolsMenu.addItem(.separator())
        toolsMenu.addItem(actionMenuItem("Add Watermark...", action: .addWatermark))
        toolsMenu.addItem(actionMenuItem("Add Header/Footer...", action: .addHeaderFooter))
        toolsMenu.addItem(.separator())
        toolsMenu.addItem(actionMenuItem("Password & Security...", action: .security))
        toolsMenu.addItem(actionMenuItem("Redact Content...", action: .redact))
        toolsMenu.addItem(.separator())
        toolsMenu.addItem(actionMenuItem("Accessibility Check...", action: .accessibilityCheck))

        let toolsMenuItem = NSMenuItem(title: "Tools", action: nil, keyEquivalent: "")
        toolsMenuItem.submenu = toolsMenu
        mainMenu.addItem(toolsMenuItem)

        // ── Pages menu ──
        let pagesMenu = NSMenu(title: "Pages")
        pagesMenu.addItem(actionMenuItem("Insert Blank Page", action: .insertBlankPage, key: "n", modifiers: [.command, .shift]))
        pagesMenu.addItem(actionMenuItem("Delete Page", action: .deletePage))
        pagesMenu.addItem(.separator())
        pagesMenu.addItem(actionMenuItem("Rotate Clockwise", action: .rotateRight, key: "]", modifiers: [.command]))
        pagesMenu.addItem(actionMenuItem("Rotate Counter-Clockwise", action: .rotateLeft, key: "[", modifiers: [.command]))
        pagesMenu.addItem(.separator())
        pagesMenu.addItem(actionMenuItem("Extract Pages...", action: .extractPages))
        pagesMenu.addItem(actionMenuItem("Split Document...", action: .splitDocument))

        let pagesMenuItem = NSMenuItem(title: "Pages", action: nil, keyEquivalent: "")
        pagesMenuItem.submenu = pagesMenu
        mainMenu.addItem(pagesMenuItem)

        // ── Forms menu ──
        let formsMenu = NSMenu(title: "Forms")
        formsMenu.addItem(actionMenuItem("Create Form Fields", action: .createForms))
        formsMenu.addItem(actionMenuItem("Auto-Detect Fields", action: .autoDetectFields))
        formsMenu.addItem(.separator())
        formsMenu.addItem(actionMenuItem("Fill & Sign", action: .fillSign))
        formsMenu.addItem(actionMenuItem("Digital Signature...", action: .digitalSign))

        let formsMenuItem = NSMenuItem(title: "Forms", action: nil, keyEquivalent: "")
        formsMenuItem.submenu = formsMenu
        mainMenu.addItem(formsMenuItem)

        // ── Window menu ──
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(NSMenuItem(title: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m"))
        windowMenu.addItem(NSMenuItem(title: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: ""))
        windowMenu.addItem(.separator())
        windowMenu.addItem(NSMenuItem(title: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: ""))

        let windowMenuItem = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        NSApp.windowsMenu = windowMenu

        // ── Help menu ──
        let helpMenu = NSMenu(title: "Help")
        let helpMenuItem = NSMenuItem(title: "Help", action: nil, keyEquivalent: "")
        helpMenuItem.submenu = helpMenu
        mainMenu.addItem(helpMenuItem)
        NSApp.helpMenu = helpMenu

        // Replace the entire menu bar
        NSApp.mainMenu = mainMenu
    }

    private func actionMenuItem(_ title: String, action: DocumentAction, key: String = "", modifiers: NSEvent.ModifierFlags = []) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(menuAction(_:)), keyEquivalent: key)
        item.keyEquivalentModifierMask = modifiers
        item.representedObject = action.rawValue
        item.target = self
        return item
    }
}
