//
//  RecipesApp.swift
//  Recipes
//
//  Created by Craig Boyce on 3/6/25.
//

import SwiftUI

@main
struct RecipesApp: App {
    // Register the app delegate for handling app lifecycle events
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
                    .navigationTitle("Recipes")
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                // Additional cleanup if needed when app terminates
                print("App termination detected in SwiftUI lifecycle")
            }
        }
    }
}
