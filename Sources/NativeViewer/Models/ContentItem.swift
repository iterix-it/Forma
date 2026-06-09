import Foundation

struct ContentItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let url: URL
    let kind: ContentKind
    let isRemote: Bool

    init(id: UUID = UUID(), title: String, url: URL, kind: ContentKind, isRemote: Bool = false) {
        self.id = id
        self.title = title
        self.url = url
        self.kind = kind
        self.isRemote = isRemote
    }
}

struct RecentContentItem: Identifiable, Equatable, Codable {
    let id: UUID
    let title: String
    let url: URL
    let kind: ContentKind

    init(id: UUID = UUID(), title: String, url: URL, kind: ContentKind) {
        self.id = id
        self.title = title
        self.url = url
        self.kind = kind
    }
}
