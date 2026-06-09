import AppKit
import SwiftUI

struct CSVViewer: View {
    let url: URL
    let searchText: String
    let zoomScale: Double

    @State private var rows: [[String]] = []
    @State private var isTruncated = false
    @State private var errorMessage: String?

    private let previewLimit = 2_000

    var body: some View {
        Group {
            if let errorMessage {
                UnsupportedView(message: errorMessage)
            } else if rows.isEmpty {
                ProgressView()
                    .controlSize(.large)
            } else {
                VStack(spacing: 0) {
                    if isTruncated {
                        Text("Showing the first \(previewLimit.formatted()) rows for performance.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(.bar)
                    }

                    tableSummary

                    CSVTableView(rows: visibleRows, zoomScale: zoomScale)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .task(id: url) {
            loadCSV()
        }
    }

    private var maxColumnCount: Int {
        rows.map(\.count).max() ?? 0
    }

    private var tableSummary: some View {
        let totalDataRows = max(rows.count - 1, 0)
        let visibleDataRows = max(visibleRows.count - 1, 0)
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        return HStack {
            if trimmedSearchText.isEmpty {
                Text("\(totalDataRows.formatted()) rows")
            } else {
                Text("\(visibleDataRows.formatted()) of \(totalDataRows.formatted()) rows")
            }

            Spacer()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var visibleRows: [[String]] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !needle.isEmpty else {
            return rows
        }

        guard let header = rows.first else {
            return []
        }

        let matches = rows.dropFirst().filter { row in
            row.contains { value in
                value.localizedCaseInsensitiveContains(needle)
            }
        }

        return [header] + matches
    }

    private func normalized(_ row: [String]) -> [String] {
        if row.count >= maxColumnCount {
            return row
        }

        return row + Array(repeating: "", count: maxColumnCount - row.count)
    }

    private func loadCSV() {
        do {
            let rawText = try String(contentsOf: url, encoding: .utf8)
            var parsedRows = CSVParser.parse(rawText)
            isTruncated = parsedRows.count > previewLimit

            if parsedRows.count > previewLimit {
                parsedRows = Array(parsedRows.prefix(previewLimit))
            }

            rows = parsedRows
            errorMessage = nil
        } catch {
            errorMessage = "This CSV file could not be read."
        }
    }
}

struct CSVTableView: NSViewRepresentable {
    let rows: [[String]]
    let zoomScale: Double

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let tableView = NSTableView()
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsColumnReordering = true
        tableView.allowsColumnResizing = true
        tableView.columnAutoresizingStyle = .noColumnAutoresizing
        tableView.rowHeight = 32
        tableView.headerView = NSTableHeaderView()
        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.documentView = tableView

        context.coordinator.tableView = tableView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.update(rows: rows, zoomScale: zoomScale)
    }

    @MainActor
    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        weak var tableView: NSTableView?
        private var headers: [String] = []
        private var dataRows: [[String]] = []
        private var zoomScale = ViewerZoom.defaultScale

        func update(rows: [[String]], zoomScale: Double) {
            headers = rows.first ?? []
            dataRows = Array(rows.dropFirst())
            self.zoomScale = zoomScale
            tableView?.rowHeight = 32 * zoomScale
            rebuildColumns()
            tableView?.reloadData()

            if let tableView, tableView.numberOfRows > 0 {
                tableView.scrollRowToVisible(0)
            }
        }

        func numberOfRows(in tableView: NSTableView) -> Int {
            dataRows.count
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            let identifier = tableColumn?.identifier.rawValue ?? ""
            let columnIndex = Int(identifier.replacingOccurrences(of: "column-", with: "")) ?? 0
            let value = dataRows[safe: row]?[safe: columnIndex] ?? ""
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("CSVCell"), owner: self) as? NSTableCellView ?? NSTableCellView()
            let textField = cell.textField ?? NSTextField(labelWithString: "")

            textField.stringValue = value
            textField.lineBreakMode = .byTruncatingTail
            textField.maximumNumberOfLines = 2
            textField.font = .systemFont(ofSize: NSFont.smallSystemFontSize * zoomScale)
            textField.textColor = .labelColor
            textField.translatesAutoresizingMaskIntoConstraints = false

            if cell.textField == nil {
                cell.identifier = NSUserInterfaceItemIdentifier("CSVCell")
                cell.textField = textField
                cell.addSubview(textField)
                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
                    textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8),
                    textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
                ])
            }

            return cell
        }

        private func rebuildColumns() {
            guard let tableView else {
                return
            }

            let existingIdentifiers = tableView.tableColumns.map { $0.identifier.rawValue }
            let requiredIdentifiers = headers.indices.map { "column-\($0)" }

            if existingIdentifiers == requiredIdentifiers {
                updateColumnTitles()
                return
            }

            for column in tableView.tableColumns {
                tableView.removeTableColumn(column)
            }

            for index in headers.indices {
                let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("column-\(index)"))
                column.title = headers[index].isEmpty ? "Column \(index + 1)" : headers[index]
                column.width = preferredWidth(for: index)
                column.minWidth = 90 * zoomScale
                column.maxWidth = 360 * zoomScale
                column.headerCell.font = .systemFont(ofSize: NSFont.smallSystemFontSize * zoomScale, weight: .semibold)
                tableView.addTableColumn(column)
            }
        }

        private func updateColumnTitles() {
            guard let tableView else {
                return
            }

            for index in headers.indices where index < tableView.tableColumns.count {
                let column = tableView.tableColumns[index]
                column.title = headers[index].isEmpty ? "Column \(index + 1)" : headers[index]
                column.width = preferredWidth(for: index)
                column.minWidth = 90 * zoomScale
                column.maxWidth = 360 * zoomScale
                column.headerCell.font = .systemFont(ofSize: NSFont.smallSystemFontSize * zoomScale, weight: .semibold)
            }
        }

        private func preferredWidth(for columnIndex: Int) -> CGFloat {
            let headerLength = headers[safe: columnIndex]?.count ?? 0
            let sampleLength = dataRows.prefix(40)
                .compactMap { $0[safe: columnIndex]?.count }
                .max() ?? 0
            let length = max(headerLength, min(sampleLength, 34))
            return CGFloat(max(120, min(280, length * 8 + 36))) * zoomScale
        }
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

enum CSVParser {
    static func parse(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var isInsideQuotes = false
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]

            switch character {
            case "\"":
                let nextIndex = text.index(after: index)

                if isInsideQuotes {
                    if nextIndex < text.endIndex, text[nextIndex] == "\"" {
                        field.append("\"")
                        index = nextIndex
                    } else {
                        isInsideQuotes = false
                    }
                } else {
                    isInsideQuotes = true
                }
            case "," where !isInsideQuotes:
                row.append(field)
                field = ""
            case let newline where newline.isNewline && !isInsideQuotes:
                row.append(field)
                rows.append(row)
                row = []
                field = ""
            default:
                field.append(character)
            }

            index = text.index(after: index)
        }

        row.append(field)

        if row.count > 1 || !row[0].isEmpty {
            rows.append(row)
        }

        return rows
    }
}
