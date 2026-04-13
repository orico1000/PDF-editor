import SwiftUI
import PDFKit

struct TextEditOverlay: View {
    let viewModel: DocumentViewModel

    @State private var isEditing = false
    @State private var editText = ""
    @State private var editPosition = CGPoint.zero
    @State private var editSize = CGSize(width: 200, height: 30)

    var body: some View {
        ZStack {
            // Transparent tap area to detect clicks on text
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { location in
                    if isEditing {
                        commitEdit()
                    } else {
                        beginEdit(at: location)
                    }
                }
                .allowsHitTesting(viewModel.state.editorMode == .editContent && !isEditing)

            // Text field overlay when editing
            if isEditing {
                TextEditFieldRepresentable(
                    text: $editText,
                    fontSize: 14,
                    onCommit: { commitEdit() },
                    onCancel: { cancelEdit() }
                )
                .frame(width: editSize.width, height: editSize.height)
                .background(Color.white)
                .border(Color.accentColor, width: 1)
                .shadow(color: .black.opacity(0.2), radius: 3)
                .position(editPosition)
            }
        }
        .allowsHitTesting(viewModel.state.editorMode == .editContent)
    }

    private func beginEdit(at location: CGPoint) {
        editPosition = location
        editText = ""
        isEditing = true
    }

    private func commitEdit() {
        guard !editText.isEmpty else {
            cancelEdit()
            return
        }
        // Create a free text annotation at the position
        let bounds = CGRect(
            x: editPosition.x - editSize.width / 2,
            y: editPosition.y - editSize.height / 2,
            width: editSize.width,
            height: editSize.height
        )
        let annotation = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
        annotation.contents = editText
        annotation.font = NSFont(name: PDFDefaults.defaultFontName, size: PDFDefaults.defaultFontSize)
        annotation.color = .clear
        annotation.fontColor = .black

        if let doc = viewModel.pdfDocument,
           let page = doc.page(at: viewModel.state.currentPageIndex) {
            page.addAnnotation(annotation)
            viewModel.markDocumentEdited()
        }

        isEditing = false
        editText = ""
    }

    private func cancelEdit() {
        isEditing = false
        editText = ""
    }
}

struct TextEditFieldRepresentable: NSViewRepresentable {
    @Binding var text: String
    let fontSize: CGFloat
    let onCommit: () -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.stringValue = text
        field.font = NSFont.systemFont(ofSize: fontSize)
        field.isBezeled = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.delegate = context.coordinator
        field.becomeFirstResponder()
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: TextEditFieldRepresentable

        init(_ parent: TextEditFieldRepresentable) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let field = obj.object as? NSTextField {
                parent.text = field.stringValue
            }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onCommit()
                return true
            }
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                parent.onCancel()
                return true
            }
            return false
        }
    }
}
