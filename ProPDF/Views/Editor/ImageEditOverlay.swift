import SwiftUI
import PDFKit

struct ImageEditOverlay: View {
    let viewModel: DocumentViewModel

    @State private var selectedImageAnnotation: PDFAnnotation?
    @State private var dragOffset = CGSize.zero
    @State private var resizeHandle: ResizeHandle?
    @State private var initialBounds: CGRect = .zero

    private enum ResizeHandle {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    var body: some View {
        ZStack {
            if let annotation = selectedImageAnnotation {
                // Selection frame
                let bounds = annotation.bounds
                Rectangle()
                    .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    .frame(width: bounds.width, height: bounds.height)
                    .position(
                        x: bounds.midX + dragOffset.width,
                        y: bounds.midY + dragOffset.height
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                moveAnnotation(annotation, by: value.translation)
                                dragOffset = .zero
                            }
                    )

                // Resize handles
                ForEach([
                    (ResizeHandle.topLeft, CGPoint(x: bounds.minX, y: bounds.minY)),
                    (.topRight, CGPoint(x: bounds.maxX, y: bounds.minY)),
                    (.bottomLeft, CGPoint(x: bounds.minX, y: bounds.maxY)),
                    (.bottomRight, CGPoint(x: bounds.maxX, y: bounds.maxY))
                ], id: \.0) { handle, position in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().strokeBorder(Color.accentColor, lineWidth: 2))
                        .position(position)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    resizeHandle = handle
                                }
                                .onEnded { value in
                                    resizeAnnotation(annotation, handle: handle, delta: value.translation)
                                    resizeHandle = nil
                                }
                        )
                }
            }
        }
        .allowsHitTesting(viewModel.state.editorMode == .editContent)
        .onChange(of: viewModel.state.selectedAnnotation) { _, newValue in
            if let ann = newValue, ann.type == PDFAnnotationSubtype.stamp.rawValue {
                selectedImageAnnotation = ann
                initialBounds = ann.bounds
            } else {
                selectedImageAnnotation = nil
            }
        }
    }

    private func moveAnnotation(_ annotation: PDFAnnotation, by translation: CGSize) {
        var bounds = annotation.bounds
        bounds.origin.x += translation.width
        bounds.origin.y -= translation.height
        annotation.bounds = bounds
        viewModel.markDocumentEdited()
    }

    private func resizeAnnotation(_ annotation: PDFAnnotation, handle: ResizeHandle, delta: CGSize) {
        var bounds = annotation.bounds
        let dx = delta.width
        let dy = -delta.height

        switch handle {
        case .topLeft:
            bounds.origin.x += dx
            bounds.size.width -= dx
            bounds.size.height += dy
        case .topRight:
            bounds.size.width += dx
            bounds.size.height += dy
        case .bottomLeft:
            bounds.origin.x += dx
            bounds.origin.y += dy
            bounds.size.width -= dx
            bounds.size.height -= dy
        case .bottomRight:
            bounds.origin.y += dy
            bounds.size.width += dx
            bounds.size.height -= dy
        }

        // Enforce minimum size
        if bounds.width >= 20 && bounds.height >= 20 {
            annotation.bounds = bounds
            viewModel.markDocumentEdited()
        }
    }
}

extension ImageEditOverlay {
    // Hashable conformance for the handle tuple
    struct HandlePosition: Hashable {
        let handle: Int
        let point: CGPoint

        func hash(into hasher: inout Hasher) {
            hasher.combine(handle)
        }

        static func == (lhs: HandlePosition, rhs: HandlePosition) -> Bool {
            lhs.handle == rhs.handle
        }
    }
}
