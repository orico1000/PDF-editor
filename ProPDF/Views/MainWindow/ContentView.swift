import SwiftUI
import PDFKit

struct ContentView: View {
    let viewModel: DocumentViewModel

    // MARK: - Sheet State

    @State private var showWatermarkSheet = false
    @State private var showHeaderFooterSheet = false
    @State private var showCompareSheet = false
    @State private var showCompressSheet = false
    @State private var showSecuritySheet = false
    @State private var showMergeSheet = false
    @State private var showSplitSheet = false
    @State private var showExtractSheet = false
    @State private var showExportSheet = false
    @State private var showImportSheet = false
    @State private var showSignatureCreation = false
    @State private var showDigitalSignature = false
    @State private var showRedactionBurnIn = false
    @State private var showAccessibilityChecker = false
    @State private var showPasswordSheet = false

    // MARK: - Notification Observer

    @State private var actionObserver: Any?

    var body: some View {
        HSplitView {
            // Sidebar
            if viewModel.state.isSidebarVisible {
                SidebarView(viewModel: viewModel)
                    .frame(minWidth: 180, maxWidth: 320)
            }

            // Main content area
            ZStack {
                if viewModel.hasDocument {
                    mainContentView
                } else {
                    emptyStateView
                }

                // Mode-specific overlays
                modeOverlays

                // Loading overlay
                if viewModel.state.isLoading {
                    ProgressOverlay(message: "Processing...")
                }
            }
            .frame(minWidth: 400)

            // Inspector
            if viewModel.state.isInspectorVisible {
                inspectorView
                    .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)
            }
        }
        .toolbar {
            ProPDFToolbarContent(viewModel: viewModel)
        }
        .overlay(alignment: .bottom) {
            StatusBarView(viewModel: viewModel)
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.state.showError },
            set: { viewModel.state.showError = $0 }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let message = viewModel.state.errorMessage {
                Text(message)
            }
        }
        .sheet(isPresented: $showWatermarkSheet) {
            WatermarkSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showHeaderFooterSheet) {
            HeaderFooterSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showCompareSheet) {
            CompareSetupSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showSecuritySheet) {
            PasswordSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showMergeSheet) {
            MergeDocumentsSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showSplitSheet) {
            SplitDocumentSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showExtractSheet) {
            ExtractPagesSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showExportSheet) {
            ExportSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showImportSheet) {
            ImportSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showSignatureCreation) {
            SignatureCreationSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showDigitalSignature) {
            DigitalSignatureSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showRedactionBurnIn) {
            RedactionBurnInSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showAccessibilityChecker) {
            AccessibilityCheckerView(viewModel: viewModel)
        }
        .sheet(isPresented: $showPasswordSheet) {
            PasswordSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showCompressSheet) {
            compressSheet
        }
        .onAppear { setupActionObserver() }
        .onDisappear { removeActionObserver() }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Mode-specific toolbar
            modeToolbar

            // PDF Viewer
            PDFViewerRepresentable(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No Document")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Open a PDF file to get started.")
                .font(.body)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Mode-Specific Toolbar

    @ViewBuilder
    private var modeToolbar: some View {
        switch viewModel.state.editorMode {
        case .annotate:
            AnnotationToolbar(viewModel: viewModel)
        case .formEditor:
            FormFieldToolbar(viewModel: viewModel)
        case .fillSign:
            fillSignToolbar
        case .redact:
            redactToolbar
        case .organize:
            organizeToolbar
        default:
            EmptyView()
        }
    }

    private var fillSignToolbar: some View {
        HStack(spacing: 12) {
            Button {
                showSignatureCreation = true
            } label: {
                Label("Create Signature", systemImage: "signature")
            }

            Button {
                showDigitalSignature = true
            } label: {
                Label("Digital Signature", systemImage: "checkmark.seal")
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var redactToolbar: some View {
        HStack(spacing: 12) {
            Text("Redact Mode")
                .font(.headline)
                .foregroundStyle(.red)

            Spacer()

            Button("Apply Redactions") {
                showRedactionBurnIn = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.red.opacity(0.05))
    }

    private var organizeToolbar: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.handleAction(.insertBlankPage)
            } label: {
                Label("Insert Page", systemImage: "plus.rectangle")
            }

            Button {
                viewModel.handleAction(.rotateRight)
            } label: {
                Label("Rotate Right", systemImage: "rotate.right")
            }

            Button {
                viewModel.handleAction(.rotateLeft)
            } label: {
                Label("Rotate Left", systemImage: "rotate.left")
            }

            Divider()
                .frame(height: 20)

            Button {
                showMergeSheet = true
            } label: {
                Label("Merge", systemImage: "arrow.triangle.merge")
            }

            Button {
                showSplitSheet = true
            } label: {
                Label("Split", systemImage: "scissors")
            }

            Button {
                showExtractSheet = true
            } label: {
                Label("Extract", systemImage: "arrow.up.doc")
            }

            Spacer()

            Button(role: .destructive) {
                viewModel.handleAction(.deletePage)
            } label: {
                Label("Delete Page", systemImage: "trash")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Mode Overlays

    @ViewBuilder
    private var modeOverlays: some View {
        switch viewModel.state.editorMode {
        case .editContent:
            TextEditOverlay(viewModel: viewModel)
        case .fillSign:
            SignaturePlacementView(viewModel: viewModel)
        case .formEditor:
            FormFieldOverlay(viewModel: viewModel)
        case .redact:
            RedactionToolView(viewModel: viewModel)
        default:
            EmptyView()
        }
    }

    // MARK: - Inspector

    @ViewBuilder
    private var inspectorView: some View {
        VStack(spacing: 0) {
            Text("Inspector")
                .font(.headline)
                .padding(8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    switch viewModel.state.editorMode {
                    case .annotate:
                        if viewModel.state.selectedAnnotation != nil {
                            AnnotationPropertyPanel(viewModel: viewModel)
                        } else {
                            Text("Select an annotation to edit its properties.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding()
                        }
                    case .formEditor:
                        FormFieldPropertyPanel(viewModel: viewModel)
                    default:
                        documentInfoInspector
                    }
                }
                .padding()
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    @ViewBuilder
    private var documentInfoInspector: some View {
        Group {
            LabeledContent("File Name") {
                Text(viewModel.fileName)
                    .font(.caption)
            }
            LabeledContent("Pages") {
                Text("\(viewModel.pageCount)")
                    .font(.caption)
            }

            if let doc = viewModel.pdfDocument,
               let page = doc.page(at: viewModel.state.currentPageIndex) {
                let bounds = page.bounds(for: .mediaBox)
                LabeledContent("Page Size") {
                    Text("\(Int(bounds.width)) x \(Int(bounds.height)) pts")
                        .font(.caption)
                }
            }

            if let url = viewModel.document?.fileURL,
               let size = FileCoordination.fileSizeString(for: url) {
                LabeledContent("File Size") {
                    Text(size)
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - Compress Sheet

    private var compressSheet: some View {
        VStack(spacing: 16) {
            Text("Compress PDF")
                .font(.headline)

            Text("Choose compression quality to reduce file size.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Quality", selection: .constant(CompressionQuality.medium)) {
                ForEach(CompressionQuality.allCases) { quality in
                    Text(quality.label).tag(quality)
                }
            }
            .pickerStyle(.radioGroup)

            HStack {
                Button("Cancel") {
                    showCompressSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Compress") {
                    showCompressSheet = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400)
    }

    // MARK: - Action Observer

    private func setupActionObserver() {
        actionObserver = NotificationCenter.default.addObserver(
            forName: .documentAction,
            object: nil,
            queue: .main
        ) { notification in
            guard let action = notification.object as? DocumentAction else { return }
            handleSheetAction(action)
        }
    }

    private func removeActionObserver() {
        if let observer = actionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func handleSheetAction(_ action: DocumentAction) {
        switch action {
        case .addWatermark:
            showWatermarkSheet = true
        case .addHeaderFooter:
            showHeaderFooterSheet = true
        case .compareDocuments:
            showCompareSheet = true
        case .compress:
            showCompressSheet = true
        case .security:
            showSecuritySheet = true
        case .mergeDocuments:
            showMergeSheet = true
        case .splitDocument:
            showSplitSheet = true
        case .extractPages:
            showExtractSheet = true
        case .exportImages:
            showExportSheet = true
        case .digitalSign:
            showDigitalSignature = true
        case .accessibilityCheck:
            showAccessibilityChecker = true
        default:
            break
        }
    }
}
