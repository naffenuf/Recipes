//
//  RecipeDetailView.swift
//  Recipes
//
//  Created by Craig Boyce on 3/16/25.
//

import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = true
    @State private var showWebView = true
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            if showWebView {
                WebView(url: URL(string: recipe.siteUrl) ?? URL(string: "https://example.com")!, onError: { error, response in
                    handleWebViewError(error, response: response)
                })
                .navigationTitle(recipe.name)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: HStack(spacing: 16) {
                    // Video button (only if video URL exists)
                    if !recipe.videoUrl.isEmpty, let videoUrl = URL(string: recipe.videoUrl) {
                        Button(action: {
                            openVideo()
                        }) {
                            Image(systemName: "play.circle")
                                .imageScale(.large)
                        }
                    }
                    
                    // Share button
                    Button(action: {
                        shareRecipe()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .imageScale(.large)
                    }
                })
            } else {
                // Fallback content if web view fails
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text(errorMessage)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    if !recipe.videoUrl.isEmpty {
                        Button(action: {
                            openVideo()
                        }) {
                            Label("Watch Recipe Video", systemImage: "play.circle.fill")
                                .font(.headline)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top)
                    }
                    
                    Button(action: {
                        searchYouTube()
                    }) {
                        Label("Search on YouTube", systemImage: "magnifyingglass")
                            .font(.headline)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 5)
                }
                .padding()
                .navigationTitle(recipe.name)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: Button(action: {
                    shareRecipe()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .imageScale(.large)
                })
            }
            
            // Loading overlay
            if isLoading {
                Color(.systemBackground).opacity(0.4)
                ProgressView("Loading recipe...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
                    .shadow(radius: 10)
            }
        }
        .onAppear {
            // Simulate loading time for the WebView
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isLoading = false
            }
        }
    }
    
    // Handle WebView errors including 404s
    private func handleWebViewError(_ error: Error, response: HTTPURLResponse?) {
        // Check if it's a 404 error
        let is404 = response?.statusCode == 404
        let isConnectionError = (error as NSError).domain == NSURLErrorDomain &&
                               ((error as NSError).code == NSURLErrorCannotFindHost ||
                                (error as NSError).code == NSURLErrorCannotConnectToHost)
        
        if is404 || isConnectionError {
            DispatchQueue.main.async {
                // If we have a video URL, go directly to it
                if !recipe.videoUrl.isEmpty {
                    errorMessage = "The recipe page couldn't be found. Opening the video instead."
                    showWebView = false
                    // Slight delay to show the error message before opening video
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        openVideo()
                    }
                } else {
                    // No video, show error and YouTube search option
                    errorMessage = "The recipe page couldn't be found. Would you like to search for it on YouTube?"
                    showWebView = false
                }
            }
        } else {
            // Other errors
            DispatchQueue.main.async {
                errorMessage = "There was a problem loading the recipe: \(error.localizedDescription)"
                showWebView = false
            }
        }
    }
    
    // Open the video URL with fallback to YouTube search
    private func openVideo() {
        guard !recipe.videoUrl.isEmpty else {
            searchYouTube()
            return
        }
        
        guard let videoUrl = URL(string: recipe.videoUrl) else {
            // Invalid video URL, fallback to YouTube search
            searchYouTube()
            return
        }
        
        // Check if it's a YouTube video that might be unavailable
        if videoUrl.absoluteString.contains("youtube.com/watch") || videoUrl.absoluteString.contains("youtu.be/") {
            // For YouTube videos, it's better to just search instead of trying to open potentially unavailable videos
            // This avoids the "This video is unavailable" screen
            searchYouTube()
            return
        }
        
        // For other video URLs, check if they're valid before opening
        let session = URLSession.shared
        let task = session.dataTask(with: videoUrl) { _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 404 || httpResponse.statusCode >= 400 {
                        // Video URL returned error, fallback to YouTube search
                        self.searchYouTube()
                    } else {
                        // URL is valid, open it
                        self.openURLSafely(videoUrl)
                    }
                } else if error != nil {
                    // Error loading URL, fallback to YouTube search
                    self.searchYouTube()
                } else {
                    // URL is valid, open it
                    self.openURLSafely(videoUrl)
                }
            }
        }
        task.resume()
    }
    
    // Helper method to safely open URLs with error handling for simulator
    private func openURLSafely(_ url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    // If opening fails (which can happen in simulator), fallback to search
                    self.searchYouTube()
                }
            }
        } else {
            // Can't open URL, fallback to search
            searchYouTube()
        }
    }
    
    // Search YouTube with recipe name and cuisine
    private func searchYouTube() {
        // Create a more specific search query with both name and cuisine
        // Format: "[Full Recipe Name] [Full Cuisine Name] recipe how to make"
        let fullRecipeName = recipe.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let fullCuisineName = recipe.cuisine.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Debug prints to see what's happening with special characters
        print("DEBUG - Recipe name: '\(recipe.name)'")
        print("DEBUG - Cuisine: '\(recipe.cuisine)'")
        print("DEBUG - Trimmed name: '\(fullRecipeName)'")
        
        // Handle special characters like & in recipe names
        // Replace & with "and" for better search results
        let processedName = fullRecipeName.replacingOccurrences(of: "&", with: "and")
        
        let searchQuery = "\(processedName) \(fullCuisineName) recipe how to make"
        print("DEBUG - Final search query: '\(searchQuery)'")
        
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        print("DEBUG - Encoded query: '\(encodedQuery)'")
        
        let youtubeURL = URL(string: "https://www.youtube.com/results?search_query=\(encodedQuery)")!
        
        openURLSafely(youtubeURL)
        
        // Show a message to the user that we're searching for the recipe
        DispatchQueue.main.async {
            self.errorMessage = "Searching for '\(processedName)' (\(fullCuisineName)) recipes on YouTube..."
        }
    }
    
    // Keep your existing shareRecipe() method here
    private func shareRecipe() {
        // Your existing share recipe implementation
        guard let url = URL(string: recipe.siteUrl) else { return }
        
        // Create a text representation for sharing
        let textToShare = "Check out this recipe for \(recipe.name) (\(recipe.cuisine)): \(recipe.siteUrl)"
        
        // Create an array of items to share
        var itemsToShare: [Any] = [textToShare, url]
        
        // Create an attributed string for richer text sharing
        let attributedString = NSAttributedString(string: "\(recipe.name)\n\(recipe.cuisine)\n\nView the full recipe at: \(recipe.siteUrl)", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)])
        itemsToShare.append(attributedString)
        
        // Create a custom activity provider to force more options
        class ImageActivityItemProvider: UIActivityItemProvider {
            var image: UIImage?
            var url: URL
            
            init(placeholderItem: Any, image: UIImage?, url: URL) {
                self.image = image
                self.url = url
                super.init(placeholderItem: placeholderItem)
            }
            
            override var item: Any {
                // Different item based on activity type
                switch self.activityType {
                case UIActivity.ActivityType.mail, UIActivity.ActivityType.message,
                     UIActivity.ActivityType.postToTwitter, UIActivity.ActivityType.postToFacebook:
                    if let image = self.image {
                        return image
                    }
                    return url
                default:
                    return url
                }
            }
        }
        
        // Create a placeholder image
        let placeholderImage = UIImage(systemName: "photo") ?? UIImage()
        let imageProvider = ImageActivityItemProvider(placeholderItem: placeholderImage, image: nil, url: url)
        itemsToShare.append(imageProvider)
        
        let activityVC = UIActivityViewController(
            activityItems: itemsToShare,
            applicationActivities: nil
        )
        
        // Make sure we don't exclude anything
        activityVC.excludedActivityTypes = []
        
        // Configure popover for iPad
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = UIApplication.shared.windows.first
            popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        // Present the activity view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true, completion: nil)
        }
    }
}
