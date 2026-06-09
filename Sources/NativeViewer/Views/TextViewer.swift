import SwiftUI

struct TextViewer: View {
    let url: URL
    let kind: ContentKind
    let searchText: String

    @State private var text = ""
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let errorMessage {
                UnsupportedView(message: errorMessage)
            } else if kind == .markdown {
                VStack(spacing: 0) {
                    searchSummary

                    ScrollView {
                        Text(attributedMarkdown)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .padding(28)
                    }
                }
            } else {
                VStack(spacing: 0) {
                    searchSummary

                    ScrollView([.vertical, .horizontal]) {
                        Text(text)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .padding(28)
                    }
                }
            }
        }
        .task(id: url) {
            loadText()
        }
    }

    private var attributedMarkdown: AttributedString {
        (try? AttributedString(markdown: text)) ?? AttributedString(text)
    }

    @ViewBuilder
    private var searchSummary: some View {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text("\(matchCount) matches")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(.bar)
        }
    }

    private var matchCount: Int {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !needle.isEmpty else {
            return 0
        }

        let searchableText = text as NSString
        var searchRange = NSRange(location: 0, length: searchableText.length)
        var count = 0

        while true {
            let foundRange = searchableText.range(
                of: needle,
                options: [.caseInsensitive, .diacriticInsensitive],
                range: searchRange
            )

            guard foundRange.location != NSNotFound else {
                return count
            }

            count += 1

            let nextLocation = foundRange.location + max(foundRange.length, 1)
            guard nextLocation < searchableText.length else {
                return count
            }

            searchRange = NSRange(location: nextLocation, length: searchableText.length - nextLocation)
        }
    }

    private func loadText() {
        do {
            text = try String(contentsOf: url, encoding: .utf8)
            errorMessage = nil
        } catch {
            do {
                text = try String(contentsOf: url, encoding: .isoLatin1)
                errorMessage = nil
            } catch {
                errorMessage = "This text file could not be read."
            }
        }
    }
}
