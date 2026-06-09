import SwiftUI

struct ViewerView: View {
    @EnvironmentObject private var appState: AppState
    let item: ContentItem
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            toolbar
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.bar)

            Divider()

            viewer
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.background)
        }
    }

    @ViewBuilder
    private var viewer: some View {
        switch item.kind {
        case .pdf:
            PDFViewer(url: item.url, searchText: searchText)
        case .csv:
            CSVViewer(url: item.url, searchText: searchText)
        case .text, .markdown:
            TextViewer(url: item.url, kind: item.kind, searchText: searchText)
        case .image:
            ImageViewer(url: item.url)
        case .web:
            WebViewer(url: item.url)
        case .quickLook:
            QuickLookViewer(url: item.url)
        case .unsupported:
            UnsupportedView(message: "This file format is not supported.") {
                Task { await appState.openFile() }
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button {
                appState.closeViewer()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut(.escape, modifiers: [])

            Image(systemName: item.kind.systemImage)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(item.kind.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if item.kind.supportsSearch {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search", text: $searchText)
                        .textFieldStyle(.plain)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 10)
                .frame(width: 220, height: 30)
                .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            ShareLink(item: item.url) {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.borderless)
        }
    }
}
