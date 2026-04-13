import AppKit
import PDFKit

enum EditorMode: String, CaseIterable, Identifiable {
    case viewer
    case editContent
    case annotate
    case fillSign
    case formEditor
    case organize
    case redact

    var id: String { rawValue }

    var label: String {
        switch self {
        case .viewer: return "View"
        case .editContent: return "Edit"
        case .annotate: return "Annotate"
        case .fillSign: return "Fill & Sign"
        case .formEditor: return "Form Editor"
        case .organize: return "Organize"
        case .redact: return "Redact"
        }
    }

    var systemImage: String {
        switch self {
        case .viewer: return "eye"
        case .editContent: return "pencil"
        case .annotate: return "highlighter"
        case .fillSign: return "signature"
        case .formEditor: return "rectangle.and.pencil.and.ellipsis"
        case .organize: return "rectangle.stack"
        case .redact: return "eye.slash"
        }
    }
}

enum SidebarMode: String, CaseIterable, Identifiable {
    case thumbnails
    case bookmarks
    case annotations
    case search

    var id: String { rawValue }

    var label: String {
        switch self {
        case .thumbnails: return "Thumbnails"
        case .bookmarks: return "Bookmarks"
        case .annotations: return "Annotations"
        case .search: return "Search"
        }
    }

    var systemImage: String {
        switch self {
        case .thumbnails: return "rectangle.split.3x3"
        case .bookmarks: return "bookmark"
        case .annotations: return "text.bubble"
        case .search: return "magnifyingglass"
        }
    }
}

enum AnnotationTool: String, CaseIterable, Identifiable {
    case none
    case highlight
    case underline
    case strikethrough
    case stickyNote
    case freeText
    case freehand
    case line
    case arrow
    case rectangle
    case oval
    case stamp
    case link

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return "Select"
        case .highlight: return "Highlight"
        case .underline: return "Underline"
        case .strikethrough: return "Strikethrough"
        case .stickyNote: return "Sticky Note"
        case .freeText: return "Text"
        case .freehand: return "Draw"
        case .line: return "Line"
        case .arrow: return "Arrow"
        case .rectangle: return "Rectangle"
        case .oval: return "Oval"
        case .stamp: return "Stamp"
        case .link: return "Link"
        }
    }

    var systemImage: String {
        switch self {
        case .none: return "cursor.rays"
        case .highlight: return "highlighter"
        case .underline: return "underline"
        case .strikethrough: return "strikethrough"
        case .stickyNote: return "note.text"
        case .freeText: return "textformat"
        case .freehand: return "pencil.tip"
        case .line: return "line.diagonal"
        case .arrow: return "arrow.right"
        case .rectangle: return "rectangle"
        case .oval: return "oval"
        case .stamp: return "checkmark.seal"
        case .link: return "link"
        }
    }
}

enum FormFieldType: String, CaseIterable, Identifiable {
    case textField
    case checkbox
    case radioButton
    case dropdown
    case pushButton
    case signature

    var id: String { rawValue }

    var label: String {
        switch self {
        case .textField: return "Text Field"
        case .checkbox: return "Checkbox"
        case .radioButton: return "Radio Button"
        case .dropdown: return "Dropdown"
        case .pushButton: return "Button"
        case .signature: return "Signature"
        }
    }

    var systemImage: String {
        switch self {
        case .textField: return "character.cursor.ibeam"
        case .checkbox: return "checkmark.square"
        case .radioButton: return "circle.inset.filled"
        case .dropdown: return "chevron.down.square"
        case .pushButton: return "button.horizontal.top.press"
        case .signature: return "signature"
        }
    }
}

enum StampType: String, CaseIterable, Identifiable {
    case approved
    case notApproved
    case draft
    case final_
    case confidential
    case forComment
    case void_
    case asIs
    case revised
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .approved: return "APPROVED"
        case .notApproved: return "NOT APPROVED"
        case .draft: return "DRAFT"
        case .final_: return "FINAL"
        case .confidential: return "CONFIDENTIAL"
        case .forComment: return "FOR COMMENT"
        case .void_: return "VOID"
        case .asIs: return "AS IS"
        case .revised: return "REVISED"
        case .custom: return "Custom..."
        }
    }

    var color: NSColor {
        switch self {
        case .approved: return .systemGreen
        case .notApproved: return .systemRed
        case .draft: return .systemOrange
        case .final_: return .systemBlue
        case .confidential: return .systemRed
        case .forComment: return .systemPurple
        case .void_: return .systemRed
        case .asIs: return .systemGray
        case .revised: return .systemTeal
        case .custom: return .systemGray
        }
    }
}

enum CompressionQuality: String, CaseIterable, Identifiable {
    case low
    case medium
    case high
    case maximum

    var id: String { rawValue }

    var label: String {
        switch self {
        case .low: return "Low (Smallest File)"
        case .medium: return "Medium"
        case .high: return "High"
        case .maximum: return "Maximum (Best Quality)"
        }
    }

    var jpegQuality: CGFloat {
        switch self {
        case .low: return 0.3
        case .medium: return 0.5
        case .high: return 0.75
        case .maximum: return 0.9
        }
    }

    var maxDPI: Int {
        switch self {
        case .low: return 72
        case .medium: return 150
        case .high: return 225
        case .maximum: return 300
        }
    }
}

struct PDFDefaults {
    static let pageWidth: CGFloat = 612  // US Letter
    static let pageHeight: CGFloat = 792
    static let defaultPageSize = CGSize(width: pageWidth, height: pageHeight)
    static let defaultMargin: CGFloat = 36 // 0.5 inch
    static let thumbnailSize = CGSize(width: 120, height: 160)
    static let ocrDPI: CGFloat = 300
    static let highlightColor = NSColor.yellow.withAlphaComponent(0.5)
    static let redactionColor = NSColor.black
    static let watermarkOpacity: CGFloat = 0.3
    static let watermarkFontSize: CGFloat = 72
    static let batesNumberFormat = "%06d"
    static let searchHighlightColor = NSColor.systemYellow.withAlphaComponent(0.4)
    static let annotationDefaultColor = NSColor.systemRed
    static let annotationDefaultLineWidth: CGFloat = 1.5
    static let defaultFontName = "Helvetica"
    static let defaultFontSize: CGFloat = 12.0
}
