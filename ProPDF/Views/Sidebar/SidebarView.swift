import SwiftUI

struct SidebarView: View {
    let viewModel: DocumentViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Mode picker
            Picker("Sidebar", selection: Binding(
                get: { viewModel.state.sidebarMode },
                set: { viewModel.state.sidebarMode = $0 }
            )) {
                ForEach(SidebarMode.allCases) { mode in
                    Label(mode.label, systemImage: mode.systemImage)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(8)

            Divider()

            // Content
            switch viewModel.state.sidebarMode {
            case .thumbnails:
                ThumbnailSidebarView(viewModel: viewModel)
            case .bookmarks:
                BookmarkSidebarView(viewModel: viewModel)
            case .annotations:
                AnnotationListView(viewModel: viewModel)
            case .search:
                SearchResultsView(viewModel: viewModel)
            }
        }
        .frame(minWidth: 180, idealWidth: 220, maxWidth: 320)
    }
}
