import SwiftUI

struct StatusBarView: View {
    let viewModel: DocumentViewModel

    @State private var goToPageText = ""

    var body: some View {
        HStack(spacing: 16) {
            // Page indicator
            HStack(spacing: 4) {
                Text("Page")
                    .foregroundStyle(.secondary)

                TextField("", text: $goToPageText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 44)
                    .multilineTextAlignment(.center)
                    .onSubmit {
                        if let page = Int(goToPageText) {
                            viewModel.viewer.goToPage(page - 1)
                        }
                        syncPageText()
                    }

                Text("of \(viewModel.pageCount)")
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 14)

            // Zoom percentage
            Text(viewModel.viewer.zoomPercentage)
                .foregroundStyle(.secondary)
                .frame(width: 50)

            Divider()
                .frame(height: 14)

            // File size
            if let url = viewModel.document?.fileURL,
               let size = FileCoordination.fileSizeString(for: url) {
                HStack(spacing: 4) {
                    Image(systemName: "doc")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(size)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Editor mode indicator
            HStack(spacing: 4) {
                Image(systemName: viewModel.state.editorMode.systemImage)
                    .font(.caption2)
                Text(viewModel.state.editorMode.label)
            }
            .foregroundStyle(.secondary)
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { syncPageText() }
        .onChange(of: viewModel.state.currentPageIndex) { _, _ in
            syncPageText()
        }
    }

    private func syncPageText() {
        goToPageText = "\(viewModel.state.currentPageIndex + 1)"
    }
}
