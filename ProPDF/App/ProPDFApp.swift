import Foundation

// Entry point is in AppDelegate.swift via @main
// This file defines shared types used across the app.

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
