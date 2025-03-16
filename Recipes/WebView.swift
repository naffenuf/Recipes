//
//  WebView.swift
//  Recipes
//
//  Created by Craig Boyce on 3/16/25.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    var onError: ((Error, HTTPURLResponse?) -> Void)? = nil
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            // Handle navigation start - could add loading indicator here
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Handle navigation complete - could remove loading indicator here
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            // Handle navigation error
            print("WebView navigation failed: \(error.localizedDescription)")
            parent.onError?(error, nil)
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WebView provisional navigation failed: \(error.localizedDescription)")
            
            // Check for HTTP errors like 404
            if let nsError = error as NSError? {
                if nsError.domain == NSURLErrorDomain {
                    // Handle URL loading errors
                    var httpResponse: HTTPURLResponse? = nil
                    if let failingURL = nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
                        // Try to get the response code from the error directly
                        if let urlResponse = nsError.userInfo["NSErrorFailingURLResponseKey"] as? HTTPURLResponse {
                            httpResponse = urlResponse
                        }
                    }
                    parent.onError?(error, httpResponse)
                }
            } else {
                parent.onError?(error, nil)
            }
        }
    }
}

struct RecipeWebView: View {
    let url: URL
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            WebView(url: url)
                .navigationBarTitle("Recipe Details", displayMode: .inline)
                .navigationBarItems(trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                })
        }
    }
}
