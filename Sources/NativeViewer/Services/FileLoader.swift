import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
struct FileLoader {
    func pickFile() -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.item]
        panel.title = "Open File"
        panel.prompt = "Open"

        return panel.runModal() == .OK ? panel.url : nil
    }
}
