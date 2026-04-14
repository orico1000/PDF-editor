import SwiftUI
import AppKit
import PDFKit

struct StampPickerView: View {
    let viewModel: DocumentViewModel
    var onSelect: (() -> Void)?

    @State private var customStampText = ""

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text("Select Stamp")
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(StampType.allCases.filter { $0 != .custom }) { stamp in
                    StampPreview(stamp: stamp)
                        .onTapGesture {
                            applyStamp(stamp)
                        }
                }
            }

            Divider()

            // Custom stamp
            VStack(alignment: .leading, spacing: 4) {
                Text("Custom Stamp")
                    .font(.caption)
                    .fontWeight(.medium)

                HStack {
                    TextField("Custom text...", text: $customStampText)
                        .textFieldStyle(.roundedBorder)

                    Button("Add") {
                        if !customStampText.isEmpty {
                            applyCustomStamp(customStampText)
                        }
                    }
                    .disabled(customStampText.isEmpty)
                }
            }
        }
        .padding()
        .frame(width: 320)
    }

    private func applyStamp(_ stamp: StampType) {
        guard let doc = viewModel.pdfDocument,
              let page = doc.page(at: viewModel.state.currentPageIndex) else { return }

        let pageBounds = page.bounds(for: .mediaBox)
        let stampWidth: CGFloat = 200
        let stampHeight: CGFloat = 50
        let bounds = CGRect(
            x: pageBounds.midX - stampWidth / 2,
            y: pageBounds.midY - stampHeight / 2,
            width: stampWidth,
            height: stampHeight
        )

        let annotation = createStampAnnotation(
            text: stamp.displayName,
            color: stamp.color,
            bounds: bounds
        )
        page.addAnnotation(annotation)
        viewModel.markDocumentEdited()
        onSelect?()
    }

    private func applyCustomStamp(_ text: String) {
        guard let doc = viewModel.pdfDocument,
              let page = doc.page(at: viewModel.state.currentPageIndex) else { return }

        let pageBounds = page.bounds(for: .mediaBox)
        let stampWidth: CGFloat = 200
        let stampHeight: CGFloat = 50
        let bounds = CGRect(
            x: pageBounds.midX - stampWidth / 2,
            y: pageBounds.midY - stampHeight / 2,
            width: stampWidth,
            height: stampHeight
        )

        let annotation = createStampAnnotation(
            text: text.uppercased(),
            color: .systemGray,
            bounds: bounds
        )
        page.addAnnotation(annotation)
        viewModel.markDocumentEdited()
        customStampText = ""
        onSelect?()
    }

    private func createStampAnnotation(text: String, color: NSColor, bounds: CGRect) -> PDFAnnotation {
        let annotation = PDFAnnotation(bounds: bounds, forType: .stamp, withProperties: nil)
        annotation.contents = text
        annotation.color = color
        return annotation
    }
}

private struct StampPreview: View {
    let stamp: StampType

    var body: some View {
        Text(stamp.displayName)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(Color(nsColor: stamp.color))
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color(nsColor: stamp.color), lineWidth: 2)
            )
            .contentShape(Rectangle())
    }
}
