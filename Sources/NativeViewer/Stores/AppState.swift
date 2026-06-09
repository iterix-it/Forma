import AppKit
import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var currentItem: ContentItem?
    @Published var recentItems: [RecentContentItem] = []
    @Published var errorMessage: String?
    @Published var isDropTargeted = false

    private let loader = FileLoader()
    private let detector = ContentDetector()

    func openFile() async {
        guard let fileURL = loader.pickFile() else {
            return
        }

        openFile(at: fileURL)
    }

    func openFile(at fileURL: URL) {
        do {
            let item = try detector.item(forFileAt: fileURL)
            setCurrentItem(item)
        } catch {
            showError(error.localizedDescription)
        }
    }

    func openURL(_ value: String) {
        do {
            let item = try detector.item(forURLString: value)
            setCurrentItem(item)
        } catch {
            showError(error.localizedDescription)
        }
    }

    func closeViewer() {
        withAnimation(.easeInOut(duration: 0.18)) {
            currentItem = nil
            errorMessage = nil
        }
    }

    func showError(_ message: String) {
        withAnimation(.easeInOut(duration: 0.18)) {
            errorMessage = message
            currentItem = nil
        }
    }

    private func setCurrentItem(_ item: ContentItem) {
        withAnimation(.easeInOut(duration: 0.18)) {
            currentItem = item
            errorMessage = nil
        }

        if !item.isRemote {
            addRecentItem(item)
        }
    }

    private func addRecentItem(_ item: ContentItem) {
        let recent = RecentContentItem(title: item.title, url: item.url, kind: item.kind)
        recentItems.removeAll { $0.url == item.url }
        recentItems.insert(recent, at: 0)

        if recentItems.count > 8 {
            recentItems.removeLast(recentItems.count - 8)
        }
    }
}
