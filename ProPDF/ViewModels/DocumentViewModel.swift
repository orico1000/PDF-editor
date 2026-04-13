import Foundation
import PDFKit
import AppKit
import Combine

@Observable
class DocumentViewModel {
    weak var document: ProPDFDocument?
    var state: DocumentState

    // MARK: - Child ViewModels (lazy)

    private var _viewer: ViewerViewModel?
    var viewer: ViewerViewModel {
        if let vm = _viewer { return vm }
        let vm = ViewerViewModel(parent: self)
        _viewer = vm
        return vm
    }

    private var _edit: EditViewModel?
    var edit: EditViewModel {
        if let vm = _edit { return vm }
        let vm = EditViewModel(parent: self)
        _edit = vm
        return vm
    }

    private var _annotation: AnnotationViewModel?
    var annotation: AnnotationViewModel {
        if let vm = _annotation { return vm }
        let vm = AnnotationViewModel(parent: self)
        _annotation = vm
        return vm
    }

    private var _pageOrganize: PageOrganizeViewModel?
    var pageOrganize: PageOrganizeViewModel {
        if let vm = _pageOrganize { return vm }
        let vm = PageOrganizeViewModel(parent: self)
        _pageOrganize = vm
        return vm
    }

    private var _formEditor: FormEditorViewModel?
    var formEditor: FormEditorViewModel {
        if let vm = _formEditor { return vm }
        let vm = FormEditorViewModel(parent: self)
        _formEditor = vm
        return vm
    }

    private var _fillSign: FillSignViewModel?
    var fillSign: FillSignViewModel {
        if let vm = _fillSign { return vm }
        let vm = FillSignViewModel(parent: self)
        _fillSign = vm
        return vm
    }

    private var _security: SecurityViewModel?
    var security: SecurityViewModel {
        if let vm = _security { return vm }
        let vm = SecurityViewModel(parent: self)
        _security = vm
        return vm
    }

    private var _compare: CompareViewModel?
    var compare: CompareViewModel {
        if let vm = _compare { return vm }
        let vm = CompareViewModel(parent: self)
        _compare = vm
        return vm
    }

    private var _ocr: OCRViewModel?
    var ocr: OCRViewModel {
        if let vm = _ocr { return vm }
        let vm = OCRViewModel(parent: self)
        _ocr = vm
        return vm
    }

    private var _convert: ConvertViewModel?
    var convert: ConvertViewModel {
        if let vm = _convert { return vm }
        let vm = ConvertViewModel(parent: self)
        _convert = vm
        return vm
    }

    private var _batch: BatchViewModel?
    var batch: BatchViewModel {
        if let vm = _batch { return vm }
        let vm = BatchViewModel(parent: self)
        _batch = vm
        return vm
    }

    private var _watermark: WatermarkViewModel?
    var watermark: WatermarkViewModel {
        if let vm = _watermark { return vm }
        let vm = WatermarkViewModel(parent: self)
        _watermark = vm
        return vm
    }

    private var _headerFooter: HeaderFooterViewModel?
    var headerFooter: HeaderFooterViewModel {
        if let vm = _headerFooter { return vm }
        let vm = HeaderFooterViewModel(parent: self)
        _headerFooter = vm
        return vm
    }

    private var _accessibility: AccessibilityViewModel?
    var accessibility: AccessibilityViewModel {
        if let vm = _accessibility { return vm }
        let vm = AccessibilityViewModel(parent: self)
        _accessibility = vm
        return vm
    }

    private var _compress: CompressViewModel?
    var compress: CompressViewModel {
        if let vm = _compress { return vm }
        let vm = CompressViewModel(parent: self)
        _compress = vm
        return vm
    }

    // MARK: - Computed Properties

    var pdfDocument: PDFDocument? {
        document?.pdfDocument
    }

    var pageCount: Int {
        pdfDocument?.pageCount ?? 0
    }

    var hasDocument: Bool {
        pdfDocument != nil
    }

    var fileName: String {
        document?.fileURL?.lastPathComponent ?? "Untitled"
    }

    // MARK: - Initialization

    private var actionCancellable: Any?

    init(document: ProPDFDocument) {
        self.document = document
        self.state = DocumentState()

        let prefs = Preferences.shared
        state.zoomLevel = prefs.defaultZoomLevel
        state.displayMode = prefs.displayMode
        state.isSidebarVisible = prefs.showSidebar
        state.sidebarMode = prefs.sidebarMode

        setupActionListener()
    }

    // MARK: - Action Handling

    private func setupActionListener() {
        actionCancellable = NotificationCenter.default.addObserver(
            forName: .documentAction,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let action = notification.object as? DocumentAction else { return }
            self.handleAction(action)
        }
    }

    func handleAction(_ action: DocumentAction) {
        switch action {
        case .toggleSidebar:
            state.isSidebarVisible.toggle()
        case .toggleInspector:
            state.isInspectorVisible.toggle()
        case .zoomIn:
            viewer.zoomIn()
        case .zoomOut:
            viewer.zoomOut()
        case .zoomToFit:
            viewer.zoomToFit()
        case .displaySingle:
            viewer.setDisplayMode(.singlePage)
        case .displaySingleContinuous:
            viewer.setDisplayMode(.singlePageContinuous)
        case .displayTwoUp:
            viewer.setDisplayMode(.twoUp)
        case .displayTwoUpContinuous:
            viewer.setDisplayMode(.twoUpContinuous)
        case .find:
            state.sidebarMode = .search
            state.isSidebarVisible = true
        case .runOCR:
            state.editorMode = .viewer
            Task { @MainActor in
                await ocr.runOCROnAllPages()
            }
        case .compareDocuments:
            break // Handled by Compare sheet in the UI
        case .compress:
            break // Handled by Compress sheet in the UI
        case .addWatermark:
            break // Handled by Watermark sheet in the UI
        case .addHeaderFooter:
            break // Handled by Header/Footer sheet in the UI
        case .security:
            break // Handled by Security sheet in the UI
        case .redact:
            state.editorMode = .redact
        case .accessibilityCheck:
            Task { @MainActor in
                await accessibility.runCheck()
            }
        case .insertBlankPage:
            let insertAt = state.currentPageIndex + 1
            pageOrganize.insertBlankPage(at: insertAt)
        case .deletePage:
            pageOrganize.deletePage(at: state.currentPageIndex)
        case .rotateRight:
            pageOrganize.rotatePage(at: state.currentPageIndex, by: 90)
        case .rotateLeft:
            pageOrganize.rotatePage(at: state.currentPageIndex, by: -90)
        case .extractPages:
            let indices = pageOrganize.selectedPages.isEmpty
                ? IndexSet(integer: state.currentPageIndex)
                : IndexSet(pageOrganize.selectedPages)
            pageOrganize.extractPages(indices)
        case .splitDocument:
            break // Handled by Split sheet in the UI
        case .mergeDocuments:
            break // Handled by Merge sheet in the UI
        case .exportImages:
            break // Handled by Export sheet in the UI
        case .createForms:
            state.editorMode = .formEditor
        case .autoDetectFields:
            state.editorMode = .formEditor
            Task { @MainActor in
                await formEditor.autoDetectFields()
            }
        case .fillSign:
            state.editorMode = .fillSign
        case .digitalSign:
            state.editorMode = .fillSign
        }
    }

    // MARK: - Document Mutation

    func markDocumentEdited() {
        document?.updateChangeCount(.changeDone)
    }

    func setEditorMode(_ mode: EditorMode) {
        state.editorMode = mode
    }

    // MARK: - Cleanup

    deinit {
        if let observer = actionCancellable {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
