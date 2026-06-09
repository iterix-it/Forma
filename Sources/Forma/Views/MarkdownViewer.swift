import SwiftUI

struct MarkdownViewer: View {
    let text: String
    let zoomScale: Double

    private var blocks: [MarkdownBlock] {
        MarkdownParser(text: text).parse()
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                    MarkdownBlockView(block: block, zoomScale: zoomScale)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(28)
        }
    }
}

private struct MarkdownBlockView: View {
    let block: MarkdownBlock
    let zoomScale: Double

    var body: some View {
        switch block {
        case let .heading(level, text):
            Text(attributedText(text))
                .font(headingFont(for: level))
                .fontWeight(headingWeight(for: level))
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(.top, level == 1 ? 8 : 5)
                .padding(.bottom, level <= 2 ? 3 : 1)
        case let .paragraph(text):
            Text(attributedText(text))
                .font(scaledFont(13))
                .lineSpacing(4 * zoomScale)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        case let .unorderedList(items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(items) { item in
                    MarkdownListRow(marker: "•", text: item.text, zoomScale: zoomScale)
                }
            }
        case let .orderedList(items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    MarkdownListRow(marker: "\(index + 1).", text: item.text, zoomScale: zoomScale)
                }
            }
        case let .checklist(items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(items) { item in
                    MarkdownListRow(
                        marker: item.isChecked ? "checkmark.square.fill" : "square",
                        text: item.text,
                        zoomScale: zoomScale,
                        usesSystemImage: true
                    )
                }
            }
        case let .quote(text):
            HStack(alignment: .top, spacing: 10) {
                Rectangle()
                    .fill(.secondary.opacity(0.45))
                    .frame(width: 3)

                Text(attributedText(text))
                    .font(scaledFont(13))
                    .foregroundStyle(.secondary)
                    .lineSpacing(4 * zoomScale)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .padding(.vertical, 2)
        case let .codeBlock(language, code):
            VStack(alignment: .leading, spacing: 8) {
                if let language {
                    Text(language)
                        .font(scaledFont(11))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                ScrollView(.horizontal) {
                    Text(code)
                        .font(.system(size: 13 * zoomScale, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(.vertical, 3)
        case .divider:
            Divider()
                .padding(.vertical, 8)
        }
    }

    private func attributedText(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
    }

    private func scaledFont(_ size: CGFloat) -> Font {
        .system(size: size * zoomScale)
    }

    private func headingFont(for level: Int) -> Font {
        switch level {
        case 1:
            scaledFont(34)
        case 2:
            scaledFont(28)
        case 3:
            scaledFont(22)
        case 4:
            scaledFont(20)
        case 5:
            scaledFont(13)
        default:
            scaledFont(12)
        }
    }

    private func headingWeight(for level: Int) -> Font.Weight {
        level <= 4 ? .semibold : .bold
    }
}

private struct MarkdownListRow: View {
    let marker: String
    let text: String
    let zoomScale: Double
    var usesSystemImage = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if usesSystemImage {
                Image(systemName: marker)
                    .font(scaledFont(13))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .trailing)
            } else {
                Text(marker)
                    .font(scaledFont(13))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .trailing)
                    .textSelection(.enabled)
            }

            Text(attributedText(text))
                .font(scaledFont(13))
                .lineSpacing(4 * zoomScale)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }

    private func attributedText(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
    }

    private func scaledFont(_ size: CGFloat) -> Font {
        .system(size: size * zoomScale)
    }
}

private enum MarkdownBlock {
    case heading(level: Int, text: String)
    case paragraph(String)
    case unorderedList([MarkdownListItem])
    case orderedList([MarkdownListItem])
    case checklist([MarkdownChecklistItem])
    case quote(String)
    case codeBlock(language: String?, code: String)
    case divider
}

private struct MarkdownListItem: Identifiable {
    let id = UUID()
    let text: String
}

private struct MarkdownChecklistItem: Identifiable {
    let id = UUID()
    let isChecked: Bool
    let text: String
}

private struct MarkdownParser {
    let text: String

    func parse() -> [MarkdownBlock] {
        let lines = text.components(separatedBy: .newlines)
        var blocks: [MarkdownBlock] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            if trimmedLine.isEmpty {
                index += 1
                continue
            }

            if trimmedLine.hasPrefix("```") {
                let parsed = parseCodeBlock(lines: lines, startIndex: index)
                blocks.append(parsed.block)
                index = parsed.nextIndex
                continue
            }

            if isDivider(trimmedLine) {
                blocks.append(.divider)
                index += 1
                continue
            }

            if let heading = parseHeading(trimmedLine) {
                blocks.append(.heading(level: heading.level, text: heading.text))
                index += 1
                continue
            }

            if trimmedLine.hasPrefix(">") {
                let parsed = parseQuote(lines: lines, startIndex: index)
                blocks.append(.quote(parsed.text))
                index = parsed.nextIndex
                continue
            }

            if let checklist = parseChecklist(lines: lines, startIndex: index) {
                blocks.append(.checklist(checklist.items))
                index = checklist.nextIndex
                continue
            }

            if let unorderedList = parseUnorderedList(lines: lines, startIndex: index) {
                blocks.append(.unorderedList(unorderedList.items))
                index = unorderedList.nextIndex
                continue
            }

            if let orderedList = parseOrderedList(lines: lines, startIndex: index) {
                blocks.append(.orderedList(orderedList.items))
                index = orderedList.nextIndex
                continue
            }

            let parsed = parseParagraph(lines: lines, startIndex: index)
            blocks.append(.paragraph(parsed.text))
            index = parsed.nextIndex
        }

        return blocks
    }

    private func parseCodeBlock(lines: [String], startIndex: Int) -> (block: MarkdownBlock, nextIndex: Int) {
        let openingLine = lines[startIndex].trimmingCharacters(in: .whitespaces)
        let language = openingLine.dropFirst(3).trimmingCharacters(in: .whitespacesAndNewlines)
        var codeLines: [String] = []
        var index = startIndex + 1

        while index < lines.count {
            let line = lines[index]

            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                return (
                    .codeBlock(language: language.isEmpty ? nil : language, code: codeLines.joined(separator: "\n")),
                    index + 1
                )
            }

            codeLines.append(line)
            index += 1
        }

        return (
            .codeBlock(language: language.isEmpty ? nil : language, code: codeLines.joined(separator: "\n")),
            index
        )
    }

    private func parseHeading(_ line: String) -> (level: Int, text: String)? {
        var level = 0

        for character in line {
            if character == "#" {
                level += 1
            } else {
                break
            }
        }

        guard (1...6).contains(level), line.dropFirst(level).first == " " else {
            return nil
        }

        let text = line.dropFirst(level).trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? nil : (level, text)
    }

    private func parseQuote(lines: [String], startIndex: Int) -> (text: String, nextIndex: Int) {
        var quoteLines: [String] = []
        var index = startIndex

        while index < lines.count {
            let trimmedLine = lines[index].trimmingCharacters(in: .whitespaces)

            guard trimmedLine.hasPrefix(">") else {
                break
            }

            quoteLines.append(trimmedLine.dropFirst().trimmingCharacters(in: .whitespaces))
            index += 1
        }

        return (quoteLines.joined(separator: "\n"), index)
    }

    private func parseChecklist(lines: [String], startIndex: Int) -> (items: [MarkdownChecklistItem], nextIndex: Int)? {
        var items: [MarkdownChecklistItem] = []
        var index = startIndex

        while index < lines.count {
            guard let item = parseChecklistLine(lines[index]) else {
                break
            }

            items.append(item)
            index += 1
        }

        return items.isEmpty ? nil : (items, index)
    }

    private func parseUnorderedList(lines: [String], startIndex: Int) -> (items: [MarkdownListItem], nextIndex: Int)? {
        var items: [MarkdownListItem] = []
        var index = startIndex

        while index < lines.count {
            guard let item = parseUnorderedListLine(lines[index]) else {
                break
            }

            items.append(item)
            index += 1
        }

        return items.isEmpty ? nil : (items, index)
    }

    private func parseOrderedList(lines: [String], startIndex: Int) -> (items: [MarkdownListItem], nextIndex: Int)? {
        var items: [MarkdownListItem] = []
        var index = startIndex

        while index < lines.count {
            guard let item = parseOrderedListLine(lines[index]) else {
                break
            }

            items.append(item)
            index += 1
        }

        return items.isEmpty ? nil : (items, index)
    }

    private func parseParagraph(lines: [String], startIndex: Int) -> (text: String, nextIndex: Int) {
        var paragraphLines: [String] = []
        var index = startIndex

        while index < lines.count {
            let line = lines[index]
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            if trimmedLine.isEmpty || trimmedLine.hasPrefix("```") || isDivider(trimmedLine) ||
                parseHeading(trimmedLine) != nil || trimmedLine.hasPrefix(">") ||
                parseChecklistLine(line) != nil || parseUnorderedListLine(line) != nil ||
                parseOrderedListLine(line) != nil {
                break
            }

            paragraphLines.append(trimmedLine)
            index += 1
        }

        return (paragraphLines.joined(separator: " "), index)
    }

    private func parseChecklistLine(_ line: String) -> MarkdownChecklistItem? {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)

        for marker in ["- [ ] ", "* [ ] ", "+ [ ] "] {
            if trimmedLine.hasPrefix(marker) {
                return MarkdownChecklistItem(isChecked: false, text: String(trimmedLine.dropFirst(marker.count)))
            }
        }

        for marker in ["- [x] ", "- [X] ", "* [x] ", "* [X] ", "+ [x] ", "+ [X] "] {
            if trimmedLine.hasPrefix(marker) {
                return MarkdownChecklistItem(isChecked: true, text: String(trimmedLine.dropFirst(marker.count)))
            }
        }

        return nil
    }

    private func parseUnorderedListLine(_ line: String) -> MarkdownListItem? {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)

        for marker in ["- ", "* ", "+ "] {
            if trimmedLine.hasPrefix(marker), parseChecklistLine(trimmedLine) == nil {
                return MarkdownListItem(text: String(trimmedLine.dropFirst(marker.count)))
            }
        }

        return nil
    }

    private func parseOrderedListLine(_ line: String) -> MarkdownListItem? {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        guard let dotIndex = trimmedLine.firstIndex(of: ".") else {
            return nil
        }

        let number = trimmedLine[..<dotIndex]
        let textStartIndex = trimmedLine.index(after: dotIndex)

        guard !number.isEmpty, number.allSatisfy(\.isNumber),
              textStartIndex < trimmedLine.endIndex, trimmedLine[textStartIndex] == " " else {
            return nil
        }

        return MarkdownListItem(text: String(trimmedLine[trimmedLine.index(after: textStartIndex)...]))
    }

    private func isDivider(_ line: String) -> Bool {
        let characters = Array(line)

        guard characters.count >= 3 else {
            return false
        }

        return characters.allSatisfy { $0 == "-" } ||
            characters.allSatisfy { $0 == "*" } ||
            characters.allSatisfy { $0 == "_" }
    }
}
