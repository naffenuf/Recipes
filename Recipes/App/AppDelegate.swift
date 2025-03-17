//
//  AppDelegate.swift
//  Recipes
//
//  Created by Craig Boyce on 3/16/25.
//

import UIKit
import WebKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Setup code that needs to run at app launch
        print("Application did finish launching")
        
        // Configure WebKit with better error handling
        configureWebKit()
        
        return true
    }
    
    private func configureWebKit() {
        // Configure WKWebView for better performance and error handling
        if #available(iOS 14.0, *) {
            let webpagePreferences = WKWebpagePreferences()
            webpagePreferences.allowsContentJavaScript = true
            
            // Create a default configuration that can be used as a template
            let configuration = WKWebViewConfiguration()
            configuration.defaultWebpagePreferences = webpagePreferences
            configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
            
            // Set up a better debugging environment for development
            #if DEBUG
            print("WebKit debugging enabled in DEBUG mode")
            #endif
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Clean up any resources when app terminates
        print("Application will terminate - cleaning up resources")
        
        // The ImageCache class already listens for UIApplication.willTerminateNotification,
        // but we could add additional cleanup here if needed
    }
}
