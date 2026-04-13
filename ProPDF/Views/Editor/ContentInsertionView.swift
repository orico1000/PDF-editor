import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct ContentInsertionView: View {
    let viewModel: DocumentViewModel

    @State private var showImagePicker = false
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.state.editorMode == .editContent {
                HStack(spacing: 12) {
                    Button {
                        showImagePicker = true
                    } label: {
                        Label("Insert Image", systemImage: "photo")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        insertTextBlock()
                    } label: {
                        Label("Insert Text", systemImage: "textformat")
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Text("Click on the page to place content, or drag an image here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(nsColor: .controlBackgroundColor))
            }
        }
        .onDrop(of: [.image], isTargeted: $isDropTargeted) { providers in
            handleImageDrop(providers)
            return true
        }
        .fileImporter(
            isPresented: $showImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                insertImage(from: url)
            }
        }
    }

    private func insertTextBlock() {
        guard let doc = viewModel.pdfDocument,
              let page = doc.page(at: viewModel.state.currentPageIndex) else { return }

        let pageBounds = page.bounds(for: .mediaBox)
        let textBounds = CGRect(
            x: pageBounds.midX - 100,
            y: pageBounds.midY - 15,
            width: 200,
            height: 30
        )

        let annotation = PDFAnnotation(bounds: textBounds, forType: .freeText, withProperties: nil)
        annotation.contents = "New text"
        annotation.font = NSFont(name: PDFDefaults.defaultFontName, size: PDFDefaults.defaultFontSize)
        annotation.color = .clear
        annotation.fontColor = .black
        page.addAnnotation(annotation)
        viewModel.state.selectedAnnotation = annotation
        viewModel.markDocumentEdited()
    }

    private func insertImage(from url: URL) {
        guard let image = NSImage(contentsOf: url) else { return }
        addImageAnnotation(image)
    }

    private func handleImageDrop(_ providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
            DispatchQueue.main.async {
                if let url = item as? URL, let image = NSImage(contentsOf: url) {
                    addImageAnnotation(image)
                } else if let data = item as? Data, let image = NSImage(data: data) {
                    addImageAnnotation(image)
                }
            }
        }
    }

    private func addImageAnnotation(_ image: NSImage) {
        guard let doc = viewModel.pdfDocument,
              let page = doc.page(at: viewModel.state.currentPageIndex) else { return }

        let pageBounds = page.bounds(for: .mediaBox)
        let maxWidth = pageBounds.width * 0.5
        let maxHeight = pageBounds.height * 0.5

        var imgWidth = image.size.width
        var imgHeight = image.size.height

        if imgWidth > maxWidth || imgHeight > maxHeight {
            let scale = min(maxWidth / imgWidth, maxHeight / imgHeight)
            imgWidth *= scale
            imgHeight *= scale
        }

        let stampBounds = CGRect(
            x: pageBounds.midX - imgWidth / 2,
            y: pageBounds.midY - imgHeight / 2,
            width: imgWidth,
            height: imgHeight
        )

        let annotation = PDFAnnotation(bounds: stampBounds, forType: .stamp, withProperties: nil)
        if let tiff = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff) {
            annotation.setValue(bitmap, forAnnotationKey: PDFAnnotationKey(rawValue: "/AP"))
        }
        page.addAnnotation(annotation)
        viewModel.state.selectedAnnotation = annotation
        viewModel.markDocumentEdited()
    }
}
