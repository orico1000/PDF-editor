import SwiftUI

struct FormFieldToolbar: View {
    let viewModel: DocumentViewModel

    @State private var selectedFieldType: FormFieldType?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(FormFieldType.allCases) { fieldType in
                Button {
                    selectedFieldType = fieldType
                    viewModel.formEditor.selectedFieldType = fieldType
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: fieldType.systemImage)
                            .font(.body)
                        Text(fieldType.label)
                            .font(.caption2)
                    }
                    .frame(width: 64, height: 40)
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selectedFieldType == fieldType ? Color.accentColor.opacity(0.2) : Color.clear)
                )
                .help(fieldType.label)
            }

            Divider()
                .frame(height: 28)
                .padding(.horizontal, 8)

            Button {
                Task {
                    await viewModel.formEditor.autoDetectFields()
                }
            } label: {
                Label("Auto-Detect", systemImage: "wand.and.stars")
            }
            .buttonStyle(.bordered)

            Spacer()

            if viewModel.formEditor.fields.count > 0 {
                Text("\(viewModel.formEditor.fields.count) fields")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
