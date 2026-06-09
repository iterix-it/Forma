import Foundation
import UniformTypeIdentifiers

struct ContentDetector {
    func item(forFileAt url: URL) throws -> ContentItem {
        guard url.isFileURL else {
            throw ContentDetectionError.invalidFileURL
        }

        let kind = detectFileKind(url)
        let title = url.lastPathComponent.isEmpty ? "Untitled" : url.lastPathComponent
        return ContentItem(title: title, url: url, kind: kind)
    }

    func item(forURLString value: String) throws -> ContentItem {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedValue.isEmpty else {
            throw ContentDetectionError.emptyURL
        }

        let normalizedValue: String
        if trimmedValue.contains("://") {
            normalizedValue = trimmedValue
        } else {
            normalizedValue = "https://\(trimmedValue)"
        }

        guard let url = URL(string: normalizedValue), let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme), url.host != nil else {
            throw ContentDetectionError.invalidURL
        }

        return ContentItem(title: url.host ?? normalizedValue, url: url, kind: .web, isRemote: true)
    }

    private func detectFileKind(_ url: URL) -> ContentKind {
        let pathExtension = url.pathExtension.lowercased()

        if pathExtension == "pdf" {
            return .pdf
        }

        if pathExtension == "csv" || pathExtension == "tsv" {
            return .csv
        }

        if ["md", "markdown"].contains(pathExtension) {
            return .markdown
        }

        if ["txt", "rtf", "log", "json", "xml", "yaml", "yml"].contains(pathExtension) {
            return .text
        }

        if let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType {
            if type.conforms(to: .pdf) {
                return .pdf
            }

            if type.conforms(to: .image) {
                return .image
            }

            if type.conforms(to: .plainText) || type.conforms(to: .text) {
                return .text
            }

            if type.conforms(to: .commaSeparatedText) {
                return .csv
            }
        }

        return .quickLook
    }
}

enum ContentDetectionError: LocalizedError {
    case emptyURL
    case invalidURL
    case invalidFileURL

    var errorDescription: String? {
        switch self {
        case .emptyURL:
            "Enter a URL to open."
        case .invalidURL:
            "The URL is not valid. Use an http or https address."
        case .invalidFileURL:
            "The selected item is not a valid local file."
        }
    }
}
