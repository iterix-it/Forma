import AppKit
import SwiftUI

struct ImageViewer: View {
    let url: URL
    let zoomScale: Double

    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                ScrollView([.horizontal, .vertical]) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(zoomScale)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(24)
                }
            } else {
                UnsupportedView(message: "This image could not be loaded.")
            }
        }
        .task(id: url) {
            image = NSImage(contentsOf: url)
        }
    }
}
