import PDFKit
import SwiftUI

struct PDFViewer: NSViewRepresentable {
    let url: URL
    let searchText: String

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .clear
        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        guard nsView.document?.documentURL != url else {
            updateSearch(in: nsView)
            return
        }

        nsView.document = PDFDocument(url: url)
        updateSearch(in: nsView)
    }

    private func updateSearch(in pdfView: PDFView) {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSearchText.isEmpty else {
            pdfView.highlightedSelections = nil
            return
        }

        let selections = pdfView.document?.findString(trimmedSearchText, withOptions: .caseInsensitive) ?? []
        pdfView.highlightedSelections = selections

        if let firstSelection = selections.first {
            pdfView.go(to: firstSelection)
        }
    }
}
