import Quartz
import SwiftUI

struct QuickLookViewer: View {
    let url: URL
    let zoomScale: Double

    var body: some View {
        QuickLookPreview(url: url)
            .scaleEffect(zoomScale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct QuickLookPreview: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> QLPreviewView {
        let previewView = QLPreviewView(frame: .zero, style: .normal)
        previewView?.autostarts = true
        return previewView ?? QLPreviewView()
    }

    func updateNSView(_ nsView: QLPreviewView, context: Context) {
        nsView.previewItem = url as NSURL
    }
}
