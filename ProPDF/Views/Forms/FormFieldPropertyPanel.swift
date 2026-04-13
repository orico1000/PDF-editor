import SwiftUI

struct FormFieldPropertyPanel: View {
    let viewModel: DocumentViewModel

    @State private var fieldName: String = ""
    @State private var isRequired: Bool = false
    @State private var isReadOnly: Bool = false
    @State private var defaultValue: String = ""
    @State private var tooltip: String = ""
    @State private var options: [String] = []
    @State private var newOption: String = ""
    @State private var fontName: String = PDFDefaults.defaultFontName
    @State private var fontSize: CGFloat = PDFDefaults.defaultFontSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Form Field Properties")
                .font(.headline)

            if let index = viewModel.formEditor.selectedFieldIndex,
               index < viewModel.formEditor.fields.count {
                let field = viewModel.formEditor.fields[index]

                // Type
                LabeledContent("Type") {
                    Label(field.fieldType.label, systemImage: field.fieldType.systemImage)
                        .font(.caption)
                }

                Divider()

                // Name
                VStack(alignment: .leading, spacing: 4) {
                    Text("Field Name")
                        .font(.caption)
                        .fontWeight(.medium)
                    TextField("Field name", text: $fieldName)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: fieldName) { _, newValue in
                            viewModel.formEditor.updateField(at: index) { $0.name = newValue }
                        }
                }

                // Tooltip
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tooltip")
                        .font(.caption)
                        .fontWeight(.medium)
                    TextField("Tooltip text", text: $tooltip)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: tooltip) { _, newValue in
                            viewModel.formEditor.updateField(at: index) { $0.tooltip = newValue }
                        }
                }

                // Default value
                if field.fieldType != .checkbox && field.fieldType != .radioButton {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Default Value")
                            .font(.caption)
                            .fontWeight(.medium)
                        TextField("Default value", text: $defaultValue)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: defaultValue) { _, newValue in
                                viewModel.formEditor.updateField(at: index) { $0.defaultValue = newValue }
                            }
                    }
                }

                // Options (for dropdown)
                if field.fieldType == .dropdown {
                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Options")
                            .font(.caption)
                            .fontWeight(.medium)

                        ForEach(options.indices, id: \.self) { i in
                            HStack {
                                Text(options[i])
                                    .font(.caption)
                                Spacer()
                                Button {
                                    options.remove(at: i)
                                    viewModel.formEditor.updateField(at: index) { $0.options = options }
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack {
                            TextField("New option", text: $newOption)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit { addOption(at: index) }
                            Button {
                                addOption(at: index)
                            } label: {
                                Image(systemName: "plus.circle")
                            }
                            .buttonStyle(.plain)
                            .disabled(newOption.isEmpty)
                        }
                    }
                }

                Divider()

                // Flags
                Toggle("Required", isOn: $isRequired)
                    .font(.caption)
                    .onChange(of: isRequired) { _, newValue in
                        viewModel.formEditor.updateField(at: index) { $0.isRequired = newValue }
                    }

                Toggle("Read Only", isOn: $isReadOnly)
                    .font(.caption)
                    .onChange(of: isReadOnly) { _, newValue in
                        viewModel.formEditor.updateField(at: index) { $0.isReadOnly = newValue }
                    }

                Divider()

                // Font
                FontPickerButton(fontName: $fontName, fontSize: $fontSize)
                    .onChange(of: fontName) { _, newValue in
                        viewModel.formEditor.updateField(at: index) { $0.fontName = newValue }
                    }
                    .onChange(of: fontSize) { _, newValue in
                        viewModel.formEditor.updateField(at: index) { $0.fontSize = newValue }
                    }

                Spacer()

                // Delete
                Button(role: .destructive) {
                    viewModel.formEditor.deleteField(at: index)
                } label: {
                    Label("Delete Field", systemImage: "trash")
                }
                .buttonStyle(.bordered)

            } else {
                Text("Select a form field to edit its properties.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear { loadProperties() }
        .onChange(of: viewModel.formEditor.selectedFieldIndex) { _, _ in
            loadProperties()
        }
    }

    private func loadProperties() {
        guard let index = viewModel.formEditor.selectedFieldIndex,
              index < viewModel.formEditor.fields.count else { return }
        let field = viewModel.formEditor.fields[index]
        fieldName = field.name
        isRequired = field.isRequired
        isReadOnly = field.isReadOnly
        defaultValue = field.defaultValue
        tooltip = field.tooltip
        options = field.options
        fontName = field.fontName
        fontSize = field.fontSize
    }

    private func addOption(at fieldIndex: Int) {
        guard !newOption.isEmpty else { return }
        options.append(newOption)
        viewModel.formEditor.updateField(at: fieldIndex) { $0.options = options }
        newOption = ""
    }
}
