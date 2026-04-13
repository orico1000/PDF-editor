import SwiftUI
import PDFKit

struct CompareSetupSheet: View {
    let viewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var comparisonDocumentURL: URL?
    @State private var comparisonDocumentName: String = "None selected"
    @State private var isComparing = false
    @State private var showComparisonView = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Compare Documents")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Compare the current document with another PDF to find differences.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Divider()

            // Current document
            GroupBox {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(.accent)
                    VStack(alignment: .leading) {
                        Text("Current Document")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text(viewModel.fileName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(viewModel.pageCount) pages")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } label: {
                Text("Document A")
                    .font(.caption)
            }

            // Comparison document
            GroupBox {
                HStack {
                    Image(systemName: "doc")
                        .foregroundStyle(comparisonDocumentURL != nil ? .accent : .secondary)
                    VStack(alignment: .leading) {
                        Text("Comparison Document")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text(comparisonDocumentName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Choose...") {
                        selectDocument()
                    }
                    .buttonStyle(.bordered)
                }
            } label: {
                Text("Document B")
                    .font(.caption)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Divider()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Compare") {
                    startComparison()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(comparisonDocumentURL == nil || isComparing)
            }
        }
        .padding()
        .frame(width: 460)
        .overlay {
            if isComparing {
                ProgressOverlay(message: "Comparing documents...")
            }
        }
        .sheet(isPresented: $showComparisonView) {
            ComparisonView(viewModel: viewModel)
                .frame(minWidth: 900, minHeight: 600)
        }
    }

    private func selectDocument() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.pdf]
        if panel.runModal() == .OK, let url = panel.url {
            comparisonDocumentURL = url
            comparisonDocumentName = url.lastPathComponent
        }
    }

    private func startComparison() {
        guard let url = comparisonDocumentURL else {
            errorMessage = "Please select a document to compare."
            return
        }

        guard let comparisonDoc = PDFDocument(url: url) else {
            errorMessage = "Failed to load the comparison document."
            return
        }

        isComparing = true
        errorMessage = nil

        Task {
            await viewModel.compare.compare(with: comparisonDoc)
            await MainActor.run {
                isComparing = false
                showComparisonView = true
            }
        }
    }
}
