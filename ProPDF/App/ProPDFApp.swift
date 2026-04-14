import Foundation

// Shared types used across the app.
// Entry point is in main.swift.

enum DocumentAction: String {
    case toggleSidebar, toggleInspector
    case zoomIn, zoomOut, zoomToFit
    case displaySingle, displaySingleContinuous, displayTwoUp, displayTwoUpContinuous
    case find
    case runOCR, compareDocuments, compress
    case addWatermark, addHeaderFooter
    case security, redact
    case accessibilityCheck
    case insertBlankPage, deletePage
    case rotateRight, rotateLeft
    case extractPages, splitDocument
    case mergeDocuments
    case exportImages
    case createForms, autoDetectFields
    case fillSign, digitalSign
}

extension Notification.Name {
    static let documentAction = Notification.Name("ProPDFDocumentAction")
}
