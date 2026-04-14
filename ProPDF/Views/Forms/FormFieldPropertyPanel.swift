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

            if let field = viewModel.formEditor.selectedField {

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
                            var updated = field
                            updated.name = newValue
                            viewModel.formEditor.updateField(updated)
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
                            var updated = field
                            updated.tooltip = newValue
                            viewModel.formEditor.updateField(updated)
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
                                var updated = field
                                updated.defaultValue = newValue
                                viewModel.formEditor.updateField(updated)
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
                                    var updated = field
                                    updated.options = options
                                    viewModel.formEditor.updateField(updated)
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
                                .onSubmit { addOption(for: field) }
                            Button {
                                addOption(for: field)
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
                        var updated = field
                        updated.isRequired = newValue
                        viewModel.formEditor.updateField(updated)
                    }

                Toggle("Read Only", isOn: $isReadOnly)
                    .font(.caption)
                    .onChange(of: isReadOnly) { _, newValue in
                        var updated = field
                        updated.isReadOnly = newValue
                        viewModel.formEditor.updateField(updated)
                    }

                Divider()

                // Font
                FontPickerButton(fontName: $fontName, fontSize: $fontSize)
                    .onChange(of: fontName) { _, newValue in
                        var updated = field
                        updated.fontName = newValue
                        viewModel.formEditor.updateField(updated)
                    }
                    .onChange(of: fontSize) { _, newValue in
                        var updated = field
                        updated.fontSize = newValue
                        viewModel.formEditor.updateField(updated)
                    }

                Spacer()

                // Delete
                Button(role: .destructive) {
                    viewModel.formEditor.deleteField(field)
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
        .onChange(of: viewModel.formEditor.selectedField?.id) { _, _ in
            loadProperties()
        }
    }

    private func loadProperties() {
        guard let field = viewModel.formEditor.selectedField else { return }
        fieldName = field.name
        isRequired = field.isRequired
        isReadOnly = field.isReadOnly
        defaultValue = field.defaultValue
        tooltip = field.tooltip
        options = field.options
        fontName = field.fontName
        fontSize = field.fontSize
    }

    private func addOption(for field: FormFieldModel) {
        guard !newOption.isEmpty else { return }
        options.append(newOption)
        var updated = field
        updated.options = options
        viewModel.formEditor.updateField(updated)
        newOption = ""
    }
}
