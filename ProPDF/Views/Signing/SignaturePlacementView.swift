import SwiftUI
import PDFKit

struct SignaturePlacementView: View {
    let viewModel: DocumentViewModel

    @State private var signaturePosition = CGPoint(x: 300, y: 400)
    @State private var signatureSize = CGSize(width: 200, height: 60)
    @State private var dragOffset = CGSize.zero
    @State private var isPlacing = false

    var body: some View {
        ZStack {
            if isPlacing, let signature = viewModel.fillSign.currentSignature {
                let signatureImage = signature.renderToImage(size: signatureSize)

                // Signature preview
                Image(nsImage: signatureImage)
                    .resizable()
                    .frame(width: signatureSize.width, height: signatureSize.height)
                    .background(Color.white.opacity(0.5))
                    .border(Color.accentColor, width: 1)
                    .shadow(color: .black.opacity(0.2), radius: 3)
                    .position(
                        x: signaturePosition.x + dragOffset.width,
                        y: signaturePosition.y + dragOffset.height
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                signaturePosition.x += value.translation.width
                                signaturePosition.y += value.translation.height
                                dragOffset = .zero
                            }
                    )

                // Controls
                VStack {
                    Spacer()

                    HStack(spacing: 16) {
                        Spacer()

                        // Size controls
                        HStack(spacing: 8) {
                            Text("Size:")
                                .font(.caption)
                            Slider(
                                value: Binding(
                                    get: { signatureSize.width },
                                    set: { newWidth in
                                        let ratio = signatureSize.height / signatureSize.width
                                        signatureSize.width = newWidth
                                        signatureSize.height = newWidth * ratio
                                    }
                                ),
                                in: 100...400
                            )
                            .frame(width: 120)
                        }

                        Button("Place Signature") {
                            placeSignature()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Cancel") {
                            isPlacing = false
                            viewModel.fillSign.currentSignature = nil
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(.regularMaterial)
                }
            }
        }
        .allowsHitTesting(viewModel.state.editorMode == .fillSign)
        .onChange(of: viewModel.fillSign.currentSignature) { _, newValue in
            isPlacing = newValue != nil
            if newValue != nil {
                signaturePosition = CGPoint(x: 300, y: 400)
                signatureSize = CGSize(width: 200, height: 60)
            }
        }
    }

    private func placeSignature() {
        guard let signature = viewModel.fillSign.currentSignature,
              let doc = viewModel.pdfDocument,
              let page = doc.page(at: viewModel.state.currentPageIndex) else { return }

        let image = signature.renderToImage(size: signatureSize)

        let bounds = CGRect(
            x: signaturePosition.x - signatureSize.width / 2,
            y: signaturePosition.y - signatureSize.height / 2,
            width: signatureSize.width,
            height: signatureSize.height
        )

        let annotation = PDFAnnotation(bounds: bounds, forType: .stamp, withProperties: nil)
        annotation.contents = "Signature: \(signature.name)"
        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData) {
            annotation.setValue(bitmap, forAnnotationKey: PDFAnnotationKey(rawValue: "/AP"))
        }

        page.addAnnotation(annotation)
        viewModel.markDocumentEdited()

        isPlacing = false
        viewModel.fillSign.currentSignature = nil
    }
}
