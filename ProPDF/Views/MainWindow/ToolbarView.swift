import SwiftUI

struct ProPDFToolbarContent: ToolbarContent {
    let viewModel: DocumentViewModel

    var body: some ToolbarContent {
        // Sidebar toggle
        ToolbarItem(placement: .navigation) {
            Button {
                viewModel.state.isSidebarVisible.toggle()
            } label: {
                Image(systemName: "sidebar.leading")
            }
            .help("Toggle Sidebar")
        }

        // Editor mode picker
        ToolbarItem(placement: .principal) {
            Picker("Mode", selection: Binding(
                get: { viewModel.state.editorMode },
                set: { viewModel.setEditorMode($0) }
            )) {
                ForEach(EditorMode.allCases) { mode in
                    Label(mode.label, systemImage: mode.systemImage)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 500)
        }

        // Zoom controls
        ToolbarItemGroup(placement: .automatic) {
            Button {
                viewModel.viewer.zoomOut()
            } label: {
                Image(systemName: "minus.magnifyingglass")
            }
            .help("Zoom Out")

            Text(viewModel.viewer.zoomPercentage)
                .frame(width: 50)
                .font(.caption)
                .monospacedDigit()

            Button {
                viewModel.viewer.zoomIn()
            } label: {
                Image(systemName: "plus.magnifyingglass")
            }
            .help("Zoom In")

            Button {
                viewModel.viewer.zoomToFit()
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
            }
            .help("Zoom to Fit")
        }

        // Inspector toggle
        ToolbarItem(placement: .automatic) {
            Button {
                viewModel.state.isInspectorVisible.toggle()
            } label: {
                Image(systemName: "sidebar.trailing")
            }
            .help("Toggle Inspector")
        }
    }
}
