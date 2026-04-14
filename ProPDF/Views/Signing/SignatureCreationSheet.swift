import SwiftUI
import AppKit

struct SignatureCreationSheet: View {
    let viewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: SignatureTab = .draw
    @State private var typedText = ""
    @State private var typedFontName = "Snell Roundhand"
    @State private var signatureName = "My Signature"
    @State private var drawingStrokes: [[CGPoint]] = []
    @State private var importedImage: NSImage?

    enum SignatureTab: String, CaseIterable {
        case draw = "Draw"
        case type = "Type"
        case image = "Import"
    }

    private let scriptFonts = [
        "Snell Roundhand",
        "Bradley Hand",
        "Brush Script MT",
        "Zapfino",
        "American Typewriter"
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("Create Signature")
                .font(.title3)
                .fontWeight(.semibold)

            // Tab selector
            Picker("Method", selection: $selectedTab) {
                ForEach(SignatureTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            // Content
            switch selectedTab {
            case .draw:
                drawTab
            case .type:
                typeTab
            case .image:
                imageTab
            }

            Divider()

            // Name
            HStack {
                Text("Name:")
                    .font(.caption)
                TextField("Signature name", text: $signatureName)
                    .textFieldStyle(.roundedBorder)
            }

            // Buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create") {
                    createSignature()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canCreate)
            }
        }
        .padding()
        .frame(width: 450, height: 400)
    }

    // MARK: - Draw Tab

    private var drawTab: some View {
        VStack(spacing: 8) {
            Text("Draw your signature below")
                .font(.caption)
                .foregroundStyle(.secondary)

            DrawingCanvasView(
                lineColor: .black,
                lineWidth: 2.0,
                onStrokeCompleted: { stroke in
                    drawingStrokes.append(stroke)
                }
            )
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button("Clear") {
                drawingStrokes.removeAll()
            }
            .buttonStyle(.bordered)
            .disabled(drawingStrokes.isEmpty)
        }
    }

    // MARK: - Type Tab

    private var typeTab: some View {
        VStack(spacing: 12) {
            TextField("Type your name", text: $typedText)
                .textFieldStyle(.roundedBorder)
                .font(.title2)

            // Font selector
            Picker("Font", selection: $typedFontName) {
                ForEach(scriptFonts, id: \.self) { font in
                    Text(font)
                        .font(.custom(font, size: 16))
                        .tag(font)
                }
            }
            .pickerStyle(.radioGroup)

            // Preview
            if !typedText.isEmpty {
                VStack {
                    Text("Preview")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(typedText)
                        .font(.custom(typedFontName, size: 28))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        )
                }
            }
        }
    }

    // MARK: - Image Tab

    private var imageTab: some View {
        VStack(spacing: 12) {
            if let image = importedImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 150)
                    .background(Color.white)
                    .cornerRadius(8)

                Button("Remove Image") {
                    importedImage = nil
                }
                .buttonStyle(.bordered)
            } else {
                DropZoneView(
                    supportedTypes: [.image],
                    label: "Drop signature image here",
                    icon: "signature"
                ) { urls in
                    if let url = urls.first, let image = NSImage(contentsOf: url) {
                        importedImage = image
                    }
                }
                .frame(height: 150)
            }
        }
    }

    // MARK: - Logic

    private var canCreate: Bool {
        switch selectedTab {
        case .draw: return !drawingStrokes.isEmpty
        case .type: return !typedText.isEmpty
        case .image: return importedImage != nil
        }
    }

    private func createSignature() {
        let signature: SignatureModel

        switch selectedTab {
        case .draw:
            signature = SignatureModel(drawn: drawingStrokes, name: signatureName)
        case .type:
            signature = SignatureModel(typed: typedText, fontName: typedFontName, name: signatureName)
        case .image:
            guard let image = importedImage else { return }
            signature = SignatureModel(image: image, name: signatureName)
        }

        viewModel.fillSign.saveSignature(signature)
        dismiss()
    }
}
