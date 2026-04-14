import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct WatermarkSheet: View {
    let viewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var config = WatermarkConfig()
    @State private var isText = true
    @State private var watermarkText = "CONFIDENTIAL"
    @State private var imageData: Data?
    @State private var imageName: String?
    @State private var isApplying = false

    var body: some View {
        HStack(spacing: 0) {
            // Settings
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Add Watermark")
                        .font(.title3)
                        .fontWeight(.semibold)

                    // Type toggle
                    Picker("Type", selection: $isText) {
                        Text("Text").tag(true)
                        Text("Image").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: isText) { _, newValue in
                        if newValue {
                            config.type = .text(watermarkText)
                        } else if let data = imageData {
                            config.type = .image(data)
                        }
                    }

                    Divider()

                    if isText {
                        textSettings
                    } else {
                        imageSettings
                    }

                    Divider()

                    commonSettings

                    Divider()

                    // Page range
                    PageRangeSelector(pageRange: $config.pageRange, totalPages: viewModel.pageCount)

                    Divider()

                    // Buttons
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .keyboardShortcut(.cancelAction)

                        Spacer()

                        Button("Apply Watermark") {
                            applyWatermark()
                        }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.borderedProminent)
                        .disabled(isApplying)
                    }
                }
                .padding()
            }
            .frame(width: 320)

            Divider()

            // Preview
            WatermarkPreviewView(
                config: config,
                pdfDocument: viewModel.pdfDocument,
                pageIndex: viewModel.state.currentPageIndex
            )
            .frame(minWidth: 300)
        }
        .frame(width: 660, height: 550)
        .overlay {
            if isApplying {
                ProgressOverlay(message: "Applying watermark...")
            }
        }
    }

    // MARK: - Text Settings

    private var textSettings: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Watermark Text")
                .font(.caption)
                .fontWeight(.medium)

            TextField("Enter text", text: $watermarkText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: watermarkText) { _, newValue in
                    config.type = .text(newValue)
                }

            FontPickerButton(fontName: $config.fontName, fontSize: $config.fontSize)

            ColorPickerButton(title: "Text Color", color: $config.color)
        }
    }

    // MARK: - Image Settings

    private var imageSettings: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Watermark Image")
                .font(.caption)
                .fontWeight(.medium)

            if let name = imageName {
                HStack {
                    Image(systemName: "photo")
                        .foregroundStyle(Color.accentColor)
                    Text(name)
                        .font(.caption)
                    Spacer()
                    Button("Change") { pickImage() }
                        .buttonStyle(.bordered)
                }
            } else {
                Button("Choose Image...") { pickImage() }
                    .buttonStyle(.bordered)
            }

            HStack {
                Text("Scale: \(Int(config.scale * 100))%")
                    .font(.caption)
                Slider(value: $config.scale, in: 0.1...3.0, step: 0.1)
            }
        }
    }

    // MARK: - Common Settings

    private var commonSettings: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Opacity
            HStack {
                Text("Opacity: \(Int(config.opacity * 100))%")
                    .font(.caption)
                Slider(value: $config.opacity, in: 0.05...1.0, step: 0.05)
            }

            // Rotation
            HStack {
                Text("Rotation: \(Int(config.rotation))")
                    .font(.caption)
                Slider(value: $config.rotation, in: -180...180, step: 15)
            }

            // Position
            Picker("Position:", selection: $config.position) {
                ForEach(WatermarkConfig.WatermarkPosition.allCases, id: \.self) { pos in
                    Text(pos.label).tag(pos)
                }
            }

            // Layer
            Toggle("Above content", isOn: $config.isAboveContent)
                .font(.caption)
        }
    }

    private func pickImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            if let data = try? Data(contentsOf: url) {
                imageData = data
                imageName = url.lastPathComponent
                config.type = .image(data)
            }
        }
    }

    private func applyWatermark() {
        isApplying = true

        Task {
            viewModel.watermark.config = config
            await viewModel.watermark.apply()
            await MainActor.run {
                isApplying = false
                dismiss()
            }
        }
    }
}
