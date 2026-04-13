import SwiftUI
import PDFKit

struct ThumbnailSidebarView: View {
    let viewModel: DocumentViewModel

    @State private var draggedPageIndex: Int?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(0..<viewModel.pageCount, id: \.self) { index in
                        ThumbnailItemView(
                            pageIndex: index,
                            isSelected: index == viewModel.state.currentPageIndex,
                            pdfDocument: viewModel.pdfDocument,
                            isOrganizeMode: viewModel.state.editorMode == .organize
                        )
                        .id(index)
                        .onTapGesture {
                            viewModel.viewer.goToPage(index)
                        }
                        .onDrag {
                            draggedPageIndex = index
                            return NSItemProvider(object: "\(index)" as NSString)
                        }
                        .onDrop(of: [.text], delegate: ThumbnailDropDelegate(
                            targetIndex: index,
                            draggedIndex: $draggedPageIndex,
                            viewModel: viewModel
                        ))
                    }
                }
                .padding(8)
            }
            .onChange(of: viewModel.state.currentPageIndex) { _, newValue in
                withAnimation {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }
}

private struct ThumbnailItemView: View {
    let pageIndex: Int
    let isSelected: Bool
    let pdfDocument: PDFDocument?
    let isOrganizeMode: Bool

    var body: some View {
        VStack(spacing: 4) {
            if let page = pdfDocument?.page(at: pageIndex) {
                let thumbnail = page.thumbnail(of: PDFDefaults.thumbnailSize, for: .mediaBox)
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: PDFDefaults.thumbnailSize.width,
                           maxHeight: PDFDefaults.thumbnailSize.height)
                    .background(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .strokeBorder(
                                isSelected ? Color.accentColor : Color.clear,
                                lineWidth: 2
                            )
                    )
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: PDFDefaults.thumbnailSize.width,
                           height: PDFDefaults.thumbnailSize.height)
            }

            Text("\(pageIndex + 1)")
                .font(.caption2)
                .foregroundStyle(isSelected ? .accent : .secondary)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .contextMenu {
            if isOrganizeMode {
                Button("Rotate Right") {
                    // Handled via viewModel in parent
                }
                Button("Rotate Left") {
                    // Handled via viewModel in parent
                }
                Divider()
                Button("Delete Page", role: .destructive) {
                    // Handled via viewModel in parent
                }
            }
        }
    }
}

private struct ThumbnailDropDelegate: DropDelegate {
    let targetIndex: Int
    @Binding var draggedIndex: Int?
    let viewModel: DocumentViewModel

    func dropEntered(info: DropInfo) {
        // Visual feedback handled by SwiftUI
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedIndex,
              draggedIndex != targetIndex,
              viewModel.state.editorMode == .organize else { return false }

        viewModel.pageOrganize.movePage(from: draggedIndex, to: targetIndex)
        self.draggedIndex = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
