import SwiftUI

struct ViewerView: View {
    @EnvironmentObject private var appState: AppState
    let item: ContentItem
    @State private var searchText = ""
    @State private var zoomScale = ViewerZoom.defaultScale

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
        .focusedSceneValue(\.viewerZoomScale, $zoomScale)
        .onChange(of: item.id) {
            zoomScale = ViewerZoom.defaultScale
        }
    }

    @ViewBuilder
    private var viewer: some View {
        switch item.kind {
        case .pdf:
            PDFViewer(url: item.url, searchText: searchText, zoomScale: zoomScale)
        case .csv:
            CSVViewer(url: item.url, searchText: searchText, zoomScale: zoomScale)
        case .text, .markdown:
            TextViewer(url: item.url, kind: item.kind, searchText: searchText, zoomScale: zoomScale)
        case .image:
            ImageViewer(url: item.url, zoomScale: zoomScale)
        case .web:
            WebViewer(url: item.url, zoomScale: zoomScale)
        case .quickLook:
            QuickLookViewer(url: item.url, zoomScale: zoomScale)
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

            zoomControls

            ShareLink(item: item.url) {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.borderless)
        }
    }

    private var zoomControls: some View {
        HStack(spacing: 6) {
            Button {
                ViewerZoom.zoomOut($zoomScale)
            } label: {
                Image(systemName: "minus")
            }
            .help("Zoom Out")

            Button {
                ViewerZoom.reset($zoomScale)
            } label: {
                Text(zoomScale, format: .percent.precision(.fractionLength(0)))
                    .font(.caption.monospacedDigit())
                    .frame(width: 44)
            }
            .help("Reset Zoom")

            Button {
                ViewerZoom.zoomIn($zoomScale)
            } label: {
                Image(systemName: "plus")
            }
            .help("Zoom In")
        }
        .buttonStyle(.borderless)
    }
}

enum ViewerZoom {
    static let defaultScale = 1.0
    static let minScale = 0.5
    static let maxScale = 3.0
    static let step = 0.1

    static func zoomIn(_ scale: Binding<Double>) {
        scale.wrappedValue = clamped(scale.wrappedValue + step)
    }

    static func zoomOut(_ scale: Binding<Double>) {
        scale.wrappedValue = clamped(scale.wrappedValue - step)
    }

    static func reset(_ scale: Binding<Double>) {
        scale.wrappedValue = defaultScale
    }

    static func clamped(_ scale: Double) -> Double {
        min(max(scale, minScale), maxScale)
    }
}

private struct ViewerZoomScaleKey: FocusedValueKey {
    typealias Value = Binding<Double>
}

extension FocusedValues {
    var viewerZoomScale: Binding<Double>? {
        get { self[ViewerZoomScaleKey.self] }
        set { self[ViewerZoomScaleKey.self] = newValue }
    }
}
