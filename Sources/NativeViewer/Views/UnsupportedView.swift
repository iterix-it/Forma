import SwiftUI

struct UnsupportedView: View {
    let message: String
    var openAnotherFile: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(.secondary)

            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)

            Text("Choose another file or open a supported URL.")
                .font(.callout)
                .foregroundStyle(.secondary)

            if let openAnotherFile {
                Button {
                    openAnotherFile()
                } label: {
                    Label("Open Another File", systemImage: "folder")
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
