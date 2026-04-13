import SwiftUI
import PDFKit

struct BookmarkSidebarView: View {
    let viewModel: DocumentViewModel

    @State private var bookmarks: [BookmarkModel] = []
    @State private var showAddBookmark = false
    @State private var newBookmarkLabel = ""

    var body: some View {
        VStack(spacing: 0) {
            if bookmarks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bookmark")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No Bookmarks")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Add bookmarks to quickly navigate through your document.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    OutlineGroup(bookmarks, children: \.childrenOptional) { bookmark in
                        HStack {
                            Image(systemName: "bookmark.fill")
                                .foregroundStyle(.accent)
                                .font(.caption)
                            Text(bookmark.label)
                                .lineLimit(2)
                            Spacer()
                            Text("p. \(bookmark.pageIndex + 1)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.viewer.goToPage(bookmark.pageIndex)
                        }
                        .contextMenu {
                            Button("Go to Page") {
                                viewModel.viewer.goToPage(bookmark.pageIndex)
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                removeBookmark(bookmark)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }

            Divider()

            HStack {
                Button {
                    showAddBookmark = true
                } label: {
                    Label("Add Bookmark", systemImage: "plus")
                }
                .buttonStyle(.borderless)
                .font(.caption)

                Spacer()
            }
            .padding(8)
        }
        .onAppear { loadBookmarks() }
        .sheet(isPresented: $showAddBookmark) {
            addBookmarkSheet
        }
    }

    private var addBookmarkSheet: some View {
        VStack(spacing: 16) {
            Text("Add Bookmark")
                .font(.headline)

            TextField("Bookmark Name", text: $newBookmarkLabel)
                .textFieldStyle(.roundedBorder)

            Text("For page \(viewModel.state.currentPageIndex + 1)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Button("Cancel") {
                    showAddBookmark = false
                    newBookmarkLabel = ""
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add") {
                    addBookmark()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newBookmarkLabel.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }

    private func loadBookmarks() {
        guard let doc = viewModel.pdfDocument else { return }
        bookmarks = BookmarkModel.models(from: doc)
    }

    private func addBookmark() {
        let bookmark = BookmarkModel(
            label: newBookmarkLabel.isEmpty ? "Page \(viewModel.state.currentPageIndex + 1)" : newBookmarkLabel,
            pageIndex: viewModel.state.currentPageIndex
        )
        bookmarks.append(bookmark)
        syncBookmarksToDocument()
        newBookmarkLabel = ""
        showAddBookmark = false
    }

    private func removeBookmark(_ bookmark: BookmarkModel) {
        bookmarks.removeAll { $0.id == bookmark.id }
        syncBookmarksToDocument()
    }

    private func syncBookmarksToDocument() {
        guard let doc = viewModel.pdfDocument else { return }
        let root = PDFOutline()
        for bookmark in bookmarks {
            let outline = bookmark.toPDFOutline(in: doc)
            root.insertChild(outline, at: root.numberOfChildren)
        }
        doc.outlineRoot = root
        viewModel.markDocumentEdited()
    }
}

private extension BookmarkModel {
    var childrenOptional: [BookmarkModel]? {
        children.isEmpty ? nil : children
    }
}
