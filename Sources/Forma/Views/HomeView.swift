import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var urlString = ""

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 40)

            VStack(spacing: 12) {
                Image("FormaLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 76)
                    .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                    .shadow(color: .black.opacity(0.18), radius: 12, y: 5)

                Text("Forma")
                    .font(.largeTitle.weight(.semibold))

                Text("Open files and web pages with native Apple viewers.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            dropZone

            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                        .foregroundStyle(.secondary)

                    TextField("Open URL", text: $urlString)
                        .textFieldStyle(.plain)
                        .onSubmit(openURL)

                    Button {
                        openURL()
                    } label: {
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .disabled(urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 12)
                .frame(width: 560, height: 38)
                .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            if !appState.recentItems.isEmpty {
                recentList
                    .frame(maxWidth: 560)
            }

            Spacer(minLength: 40)
        }
        .padding(32)
        .background(.regularMaterial)
        .alert("Cannot Open Content", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                appState.errorMessage = nil
            }
        } message: {
            Text(appState.errorMessage ?? "")
        }
    }

    private var dropZone: some View {
        VStack(spacing: 10) {
            Image(systemName: "square.and.arrow.down")
                .font(.title2)
                .foregroundStyle(appState.isDropTargeted ? .primary : .secondary)

            Text("Drop a file here")
                .font(.headline)

            Text("PDF, CSV, text, Markdown, images, and system-supported files")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: 560, minHeight: 150)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture {
            Task { await appState.openFile() }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(appState.isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.25), lineWidth: 1.4)
        }
        .scaleEffect(appState.isDropTargeted ? 1.015 : 1)
        .animation(.easeInOut(duration: 0.15), value: appState.isDropTargeted)
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $appState.isDropTargeted) { providers in
            guard let provider = providers.first else {
                return false
            }

            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                let fileURL = Self.fileURL(from: item)
                Task { @MainActor in
                    if let fileURL {
                        appState.openFile(at: fileURL)
                    } else {
                        appState.showError("The dropped item could not be opened.")
                    }
                }
            }

            return true
        }
    }

    private var recentList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent")
                .font(.headline)

            ForEach(appState.recentItems) { item in
                Button {
                    appState.openFile(at: item.url)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: item.kind.systemImage)
                            .foregroundStyle(.secondary)
                            .frame(width: 22)

                        Text(item.title)
                            .lineLimit(1)

                        Spacer()

                        Text(item.kind.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { appState.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    appState.errorMessage = nil
                }
            }
        )
    }

    private func openURL() {
        appState.openURL(urlString)
    }

    private nonisolated static func fileURL(from item: NSSecureCoding?) -> URL? {
        if let data = item as? Data {
            return URL(dataRepresentation: data, relativeTo: nil)
        }

        if let url = item as? URL {
            return url
        }

        if let string = item as? String {
            return URL(string: string)
        }

        return nil
    }
}
