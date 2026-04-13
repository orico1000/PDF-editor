import Cocoa
import UniformTypeIdentifiers

class PDFDocumentController: NSDocumentController {
    override var defaultType: String? {
        UTType.pdf.identifier
    }

    override var documentClassNames: [String] {
        ["ProPDFDocument"]
    }

    override func documentClass(forType typeName: String) -> AnyClass? {
        ProPDFDocument.self
    }

    override func typeForContents(of url: URL) throws -> String {
        if url.pathExtension.lowercased() == "pdf" {
            return UTType.pdf.identifier
        }
        return try super.typeForContents(of: url)
    }
}
