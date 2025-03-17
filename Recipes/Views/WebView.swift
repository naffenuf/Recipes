import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let initialUrl: URL
    var onWebViewCreated: ((WKWebView) -> Void)?
    var onPageLoaded: (() -> Void)?
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1"
        
        let request = URLRequest(url: initialUrl)
        print("Loading initial URL: \(initialUrl.absoluteString)")
        webView.load(request)
        
        onWebViewCreated?(webView)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only reload if the WebView hasn't loaded a different URL (e.g., after search fallback)
        if webView.url == nil || (webView.url?.absoluteString != initialUrl.absoluteString && !webView.url!.absoluteString.contains("youtube.com/results")) {
            let request = URLRequest(url: initialUrl)
            print("Reloading WebView with initial URL: \(initialUrl.absoluteString)")
            webView.load(request)
        } else {
            print("No reload needed for current URL: \(String(describing: webView.url?.absoluteString))")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("WebView finished loading: \(String(describing: webView.url?.absoluteString))")
            parent.onPageLoaded?()
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView failed to load with error: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WebView provisional navigation failed with error: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                    for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url {
                print("Creating new WebView for URL: \(url.absoluteString)")
                webView.load(navigationAction.request)
            }
            return nil
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            print("Navigating to: \(url.absoluteString)")
            if url.absoluteString.contains("youtube.com/watch") && (url.absoluteString.contains("unavailable") || url.absoluteString.contains("removed")) {
                print("Detected potential unavailable video redirect")
                decisionHandler(.cancel)
                parent.onPageLoaded?()
                return
            }
            decisionHandler(.allow)
        }
    }
}

struct RecipeWebView: View {
    let url: URL
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            WebView(initialUrl: url)
                .navigationBarTitle("Recipe Details", displayMode: .inline)
                .navigationBarItems(trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                })
        }
    }
}
