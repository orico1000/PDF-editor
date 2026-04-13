import SwiftUI
import PDFKit

struct FormFieldOverlay: View {
    let viewModel: DocumentViewModel

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    var body: some View {
        ZStack {
            // Transparent interaction layer
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { location in
                    if let fieldType = viewModel.formEditor.selectedFieldType {
                        addField(type: fieldType, at: location)
                    }
                }
                .allowsHitTesting(
                    viewModel.state.editorMode == .formEditor &&
                    viewModel.formEditor.selectedFieldType != nil
                )

            // Render existing fields as overlays
            ForEach(Array(viewModel.formEditor.fields.enumerated()), id: \.element.id) { index, field in
                if field.pageIndex == viewModel.state.currentPageIndex {
                    FormFieldPlaceholder(
                        field: field,
                        isSelected: viewModel.formEditor.selectedFieldIndex == index,
                        onSelect: {
                            viewModel.formEditor.selectedFieldIndex = index
                        },
                        onMove: { delta in
                            viewModel.formEditor.updateField(at: index) { f in
                                f.bounds.origin.x += delta.width
                                f.bounds.origin.y -= delta.height
                            }
                        },
                        onResize: { newSize in
                            viewModel.formEditor.updateField(at: index) { f in
                                f.bounds.size = newSize
                            }
                        }
                    )
                }
            }
        }
        .allowsHitTesting(viewModel.state.editorMode == .formEditor)
    }

    private func addField(type: FormFieldType, at location: CGPoint) {
        let defaultSize: CGSize
        switch type {
        case .textField:
            defaultSize = CGSize(width: 180, height: 24)
        case .checkbox, .radioButton:
            defaultSize = CGSize(width: 18, height: 18)
        case .dropdown:
            defaultSize = CGSize(width: 180, height: 24)
        case .pushButton:
            defaultSize = CGSize(width: 100, height: 30)
        case .signature:
            defaultSize = CGSize(width: 200, height: 60)
        }

        let bounds = CGRect(
            x: location.x - defaultSize.width / 2,
            y: location.y - defaultSize.height / 2,
            width: defaultSize.width,
            height: defaultSize.height
        )

        let field = FormFieldModel(
            fieldType: type,
            bounds: bounds,
            pageIndex: viewModel.state.currentPageIndex
        )
        viewModel.formEditor.addField(field)
    }
}

private struct FormFieldPlaceholder: View {
    let field: FormFieldModel
    let isSelected: Bool
    let onSelect: () -> Void
    let onMove: (CGSize) -> Void
    let onResize: (CGSize) -> Void

    @State private var dragOffset: CGSize = .zero

    var body: some View {
        VStack(spacing: 0) {
            fieldContent
        }
        .frame(width: field.bounds.width, height: field.bounds.height)
        .background(fieldBackground)
        .overlay(
            Rectangle()
                .strokeBorder(
                    isSelected ? Color.accentColor : Color.blue.opacity(0.5),
                    style: StrokeStyle(lineWidth: isSelected ? 2 : 1, dash: isSelected ? [] : [4, 2])
                )
        )
        .position(
            x: field.bounds.midX + dragOffset.width,
            y: field.bounds.midY + dragOffset.height
        )
        .onTapGesture { onSelect() }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    onMove(value.translation)
                    dragOffset = .zero
                }
        )
    }

    @ViewBuilder
    private var fieldContent: some View {
        switch field.fieldType {
        case .textField:
            HStack {
                Text(field.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 4)

        case .checkbox:
            Image(systemName: "square")
                .font(.caption)
                .foregroundStyle(.secondary)

        case .radioButton:
            Image(systemName: "circle")
                .font(.caption)
                .foregroundStyle(.secondary)

        case .dropdown:
            HStack {
                Text(field.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)

        case .pushButton:
            Text(field.defaultValue.isEmpty ? "Button" : field.defaultValue)
                .font(.caption2)
                .foregroundStyle(.secondary)

        case .signature:
            VStack {
                Image(systemName: "signature")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Signature")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var fieldBackground: some View {
        Color.blue.opacity(isSelected ? 0.15 : 0.08)
    }
}
