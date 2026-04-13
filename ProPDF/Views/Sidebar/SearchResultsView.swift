import SwiftUI
import PDFKit

struct SearchResultsView: View {
    let viewModel: DocumentViewModel

    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search in document...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        performSearch()
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        viewModel.viewer.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
            .padding(8)

            // Navigation controls
            if viewModel.viewer.hasSearchResults {
                HStack {
                    Text(viewModel.viewer.searchResultLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        viewModel.viewer.previousSearchResult()
                    } label: {
                        Image(systemName: "chevron.up")
                    }
                    .buttonStyle(.borderless)

                    Button {
                        viewModel.viewer.nextSearchResult()
                    } label: {
                        Image(systemName: "chevron.down")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            }

            Divider()

            // Results list
            if viewModel.viewer.isSearching {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Searching...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.viewer.searchResults.isEmpty && !searchText.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No Results")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.viewer.searchResults.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Search Document")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Enter text to find in the document.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(viewModel.viewer.searchResults.enumerated()), id: \.offset) { index, selection in
                        SearchResultRow(
                            selection: selection,
                            isCurrentResult: index == viewModel.viewer.currentSearchIndex,
                            document: viewModel.pdfDocument
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            navigateToResult(at: index)
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }

    private func performSearch() {
        Task {
            await viewModel.viewer.search(query: searchText)
        }
    }

    private func navigateToResult(at index: Int) {
        guard let doc = viewModel.pdfDocument,
              index < viewModel.viewer.searchResults.count else { return }

        viewModel.viewer.currentSearchIndex = index
        let selection = viewModel.viewer.searchResults[index]
        if let page = selection.pages.first {
            viewModel.viewer.goToPage(doc.index(for: page))
        }
    }
}

private struct SearchResultRow: View {
    let selection: PDFSelection
    let isCurrentResult: Bool
    let document: PDFDocument?

    var body: some View {
        HStack(spacing: 8) {
            if let pageLabel = pageLabel {
                Text(pageLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 30, alignment: .trailing)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(contextText)
                    .font(.caption)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isCurrentResult ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }

    private var pageLabel: String? {
        guard let page = selection.pages.first,
              let doc = document else { return nil }
        let index = doc.index(for: page)
        return "p.\(index + 1)"
    }

    private var contextText: String {
        selection.string ?? "Match"
    }
}
