import SwiftUI
import WebKit

struct WebViewer: NSViewRepresentable {
    let url: URL
    let zoomScale: Double

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsMagnification = true
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.pageZoom = zoomScale

        if nsView.url != url {
            nsView.load(URLRequest(url: url))
        }
    }
}
