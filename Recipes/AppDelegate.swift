//
//  AppDelegate.swift
//  Recipes
//
//  Created by Craig Boyce on 3/16/25.
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Setup code that needs to run at app launch
        print("Application did finish launching")
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Clean up any resources when app terminates
        print("Application will terminate - cleaning up resources")
        
        // The ImageCache class already listens for UIApplication.willTerminateNotification,
        // but we could add additional cleanup here if needed
    }
}
