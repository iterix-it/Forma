import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            if let item = appState.currentItem {
                ViewerView(item: item)
                    .transition(.opacity.combined(with: .scale(scale: 0.99)))
            } else {
                HomeView()
                    .transition(.opacity)
            }
        }
    }
}
