import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var openFilesHandler: (([URL]) -> Void)?
    private var pendingOpenFileURLs: [URL] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let fileURLs = filenames.map { URL(fileURLWithPath: $0) }
        open(fileURLs, sender: sender)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        open(urls, sender: application)
    }

    private func open(_ fileURLs: [URL], sender: NSApplication) {
        guard !fileURLs.isEmpty else {
            sender.reply(toOpenOrPrint: .failure)
            return
        }

        if let openFilesHandler {
            openFilesHandler(fileURLs)
        } else {
            pendingOpenFileURLs.append(contentsOf: fileURLs)
        }

        sender.reply(toOpenOrPrint: .success)
    }

    func setOpenFilesHandler(_ handler: @escaping ([URL]) -> Void) {
        openFilesHandler = handler

        guard !pendingOpenFileURLs.isEmpty else {
            return
        }

        let pendingURLs = pendingOpenFileURLs
        pendingOpenFileURLs.removeAll()
        handler(pendingURLs)
    }
}

@main
struct FormaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 900, minHeight: 620)
                .onOpenURL { url in
                    appState.openExternalURL(url)
                }
                .onAppear {
                    appDelegate.setOpenFilesHandler { fileURLs in
                        appState.openFiles(at: fileURLs)
                    }
                    appState.requestFileAssociationSetupIfNeeded()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open File...") {
                    Task { await appState.openFile() }
                }
                .keyboardShortcut("o", modifiers: [.command])
            }

            ViewerZoomCommands()
        }
    }
}

struct ViewerZoomCommands: Commands {
    @FocusedValue(\.viewerZoomScale) private var zoomScale

    var body: some Commands {
        CommandMenu("View") {
            Button("Zoom In") {
                if let zoomScale {
                    ViewerZoom.zoomIn(zoomScale)
                }
            }
            .keyboardShortcut("+", modifiers: [.command])
            .disabled(zoomScale == nil)

            Button("Zoom Out") {
                if let zoomScale {
                    ViewerZoom.zoomOut(zoomScale)
                }
            }
            .keyboardShortcut("-", modifiers: [.command])
            .disabled(zoomScale == nil)

            Button("Actual Size") {
                if let zoomScale {
                    ViewerZoom.reset(zoomScale)
                }
            }
            .keyboardShortcut("0", modifiers: [.command])
            .disabled(zoomScale == nil)
        }
    }
}
