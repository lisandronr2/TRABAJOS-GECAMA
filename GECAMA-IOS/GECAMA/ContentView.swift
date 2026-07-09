import SwiftUI
import WebKit

struct ContentView: View {
    var body: some View {
        GecamaWebView()
            .ignoresSafeArea()
    }
}

struct GecamaWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        // Habilitar almacenamiento local (IndexedDB, localStorage)
        let dataStore = WKWebsiteDataStore.default()
        config.websiteDataStore = dataStore

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.094, green: 0.373, blue: 0.647, alpha: 1)

        // Cargar index.html desde el bundle de la app
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Web") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

#Preview {
    ContentView()
}
