import WebKit

protocol NavigationService {
    func loadURL(_ url: URL, in webView: WKWebView)
}

class DefaultNavigationService: NavigationService {
    func loadURL(_ url: URL, in webView: WKWebView) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
