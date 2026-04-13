import SwiftUI

struct AnnotationToolbar: View {
    let viewModel: DocumentViewModel

    @State private var currentTool: AnnotationTool = .none
    @State private var showStampPicker = false

    private let textMarkupTools: [AnnotationTool] = [.highlight, .underline, .strikethrough]
    private let noteTools: [AnnotationTool] = [.stickyNote, .freeText]
    private let drawTools: [AnnotationTool] = [.freehand, .line, .arrow]
    private let shapeTools: [AnnotationTool] = [.rectangle, .oval]
    private let otherTools: [AnnotationTool] = [.stamp, .link]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                // Select tool
                toolButton(for: .none)

                separator

                // Text markup
                ForEach(textMarkupTools) { tool in
                    toolButton(for: tool)
                }

                separator

                // Notes
                ForEach(noteTools) { tool in
                    toolButton(for: tool)
                }

                separator

                // Drawing
                ForEach(drawTools) { tool in
                    toolButton(for: tool)
                }

                separator

                // Shapes
                ForEach(shapeTools) { tool in
                    toolButton(for: tool)
                }

                separator

                // Stamp
                Button {
                    showStampPicker = true
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: AnnotationTool.stamp.systemImage)
                            .font(.body)
                        Text(AnnotationTool.stamp.label)
                            .font(.caption2)
                    }
                    .frame(width: 50, height: 40)
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(currentTool == .stamp ? Color.accentColor.opacity(0.2) : Color.clear)
                )
                .popover(isPresented: $showStampPicker) {
                    StampPickerView(viewModel: viewModel) {
                        currentTool = .stamp
                        showStampPicker = false
                    }
                }

                // Link
                toolButton(for: .link)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .onChange(of: currentTool) { _, newTool in
            viewModel.annotation.currentTool = newTool
        }
    }

    private var separator: some View {
        Divider()
            .frame(height: 28)
            .padding(.horizontal, 4)
    }

    private func toolButton(for tool: AnnotationTool) -> some View {
        Button {
            currentTool = tool
        } label: {
            VStack(spacing: 2) {
                Image(systemName: tool.systemImage)
                    .font(.body)
                Text(tool.label)
                    .font(.caption2)
            }
            .frame(width: 50, height: 40)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(currentTool == tool ? Color.accentColor.opacity(0.2) : Color.clear)
        )
        .help(tool.label)
    }
}

// Extension to provide the current tool binding on AnnotationViewModel
extension AnnotationViewModel {
    // The parent ViewModel bridge - this property is expected to exist
    // on AnnotationViewModel. If not yet defined, it will be added
    // by the ViewModel creation task.
}
