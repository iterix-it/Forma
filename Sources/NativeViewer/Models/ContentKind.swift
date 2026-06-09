import Foundation

enum ContentKind: String, Codable, Equatable {
    case pdf
    case csv
    case text
    case markdown
    case image
    case web
    case quickLook
    case unsupported

    var displayName: String {
        switch self {
        case .pdf:
            "PDF"
        case .csv:
            "CSV"
        case .text:
            "Text"
        case .markdown:
            "Markdown"
        case .image:
            "Image"
        case .web:
            "Web"
        case .quickLook:
            "Preview"
        case .unsupported:
            "Unsupported"
        }
    }

    var systemImage: String {
        switch self {
        case .pdf:
            "doc.richtext"
        case .csv:
            "tablecells"
        case .text:
            "doc.text"
        case .markdown:
            "text.alignleft"
        case .image:
            "photo"
        case .web:
            "globe"
        case .quickLook:
            "eye"
        case .unsupported:
            "exclamationmark.triangle"
        }
    }

    var supportsSearch: Bool {
        switch self {
        case .pdf, .csv, .text, .markdown:
            true
        case .image, .web, .quickLook, .unsupported:
            false
        }
    }
}
