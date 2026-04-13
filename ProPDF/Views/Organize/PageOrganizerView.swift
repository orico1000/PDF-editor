import SwiftUI
import PDFKit

struct PageOrganizerView: View {
    let viewModel: DocumentViewModel

    @State private var selectedPages: Set<Int> = []
    @State private var draggedPage: Int?

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                Button {
                    selectAll()
                } label: {
                    Text("Select All")
                }
                .buttonStyle(.bordered)

                Button {
                    selectedPages.removeAll()
                } label: {
                    Text("Deselect All")
                }
                .buttonStyle(.bordered)

                Spacer()

                Text("\(selectedPages.count) of \(viewModel.pageCount) selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<viewModel.pageCount, id: \.self) { index in
                        PageThumbnailCell(
                            pageIndex: index,
                            pdfDocument: viewModel.pdfDocument,
                            isSelected: selectedPages.contains(index),
                            rotation: pdfDocument?.page(at: index)?.rotation ?? 0
                        )
                        .onTapGesture {
                            if NSEvent.modifierFlags.contains(.shift) {
                                toggleSelection(index)
                            } else if NSEvent.modifierFlags.contains(.command) {
                                toggleSelection(index)
                            } else {
                                selectedPages = [index]
                                viewModel.viewer.goToPage(index)
                            }
                        }
                        .onDrag {
                            draggedPage = index
                            return NSItemProvider(object: "\(index)" as NSString)
                        }
                        .onDrop(of: [.text], delegate: PageGridDropDelegate(
                            targetIndex: index,
                            draggedPage: $draggedPage,
                            viewModel: viewModel
                        ))
                        .contextMenu {
                            pageContextMenu(for: index)
                        }
                    }
                }
                .padding(16)
            }
        }
        .onChange(of: selectedPages) { _, newValue in
            viewModel.pageOrganize.selectedPages = newValue
        }
    }

    private var pdfDocument: PDFDocument? {
        viewModel.pdfDocument
    }

    private func toggleSelection(_ index: Int) {
        if selectedPages.contains(index) {
            selectedPages.remove(index)
        } else {
            selectedPages.insert(index)
        }
    }

    private func selectAll() {
        selectedPages = Set(0..<viewModel.pageCount)
    }

    @ViewBuilder
    private func pageContextMenu(for index: Int) -> some View {
        Button("Rotate Clockwise") {
            viewModel.pageOrganize.rotatePage(at: index, by: 90)
        }
        Button("Rotate Counter-Clockwise") {
            viewModel.pageOrganize.rotatePage(at: index, by: -90)
        }

        Divider()

        Button("Insert Blank Page After") {
            viewModel.pageOrganize.insertBlankPage(at: index + 1)
        }

        Button("Duplicate Page") {
            viewModel.pageOrganize.duplicatePage(at: index)
        }

        Divider()

        Button("Delete Page", role: .destructive) {
            viewModel.pageOrganize.deletePage(at: index)
            selectedPages.remove(index)
        }
    }
}

private struct PageGridDropDelegate: DropDelegate {
    let targetIndex: Int
    @Binding var draggedPage: Int?
    let viewModel: DocumentViewModel

    func performDrop(info: DropInfo) -> Bool {
        guard let source = draggedPage, source != targetIndex else { return false }
        viewModel.pageOrganize.movePage(from: source, to: targetIndex)
        draggedPage = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
