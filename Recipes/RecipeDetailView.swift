import SwiftUI
import WebKit

struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.presentationMode) var presentationMode
    @State private var isShowingVideo = false
    private let siteUrl: URL
    private let videoUrl: URL?
    
    @State private var videoWebView: WKWebView?
    @State private var hasLoadedSearch = false  // New flag to track search page load
    
    init(recipe: Recipe) {
        self.recipe = recipe
        self.siteUrl = URL(string: recipe.siteUrl) ?? Self.googleSearchURL(for: recipe)
        self.videoUrl = !recipe.videoUrl.isEmpty ? URL(string: recipe.videoUrl) ?? Self.googleSearchURL(for: recipe) : nil
    }
    
    var body: some View {
        ZStack {
            WebView(url: siteUrl)
                .opacity(isShowingVideo ? 0 : 1)
            
            if let videoUrl = videoUrl {
                WebView(url: videoUrl,
                       onWebViewCreated: { webView in
                           DispatchQueue.main.async {
                               self.videoWebView = webView
                           }
                       },
                       onPageLoaded: {
                           checkForVideoPlayer()
                       })
                .opacity(isShowingVideo ? 1 : 0)
            }
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: HStack(spacing: 20) {
            if videoUrl != nil {
                Button(action: toggleVideoRecipe) {
                    Image(systemName: isShowingVideo ? "doc.text" : "play.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                }
                .help(isShowingVideo ? "View Recipe Directions" : "Watch Recipe Video")
            }
            
            Button(action: shareRecipe) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
            }
        })
    }
    
    private func toggleVideoRecipe() {
        if isShowingVideo {
            if let webView = videoWebView {
                let pauseScript = """
                var player = document.getElementsByTagName('video')[0] || 
                            document.getElementById('movie_player') || 
                            window.YT?.Player;
                if (player) {
                    if (player.pause) {
                        player.pause();
                    } else if (player.pauseVideo) {
                        player.pauseVideo();
                    }
                }
                """
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    webView.evaluateJavaScript(pauseScript) { (result, error) in
                        if let error = error {
                            print("Error pausing video: \(error.localizedDescription)")
                        } else {
                            print("Video pause attempted successfully")
                        }
                    }
                    self.isShowingVideo = false
                }
            } else {
                isShowingVideo = false
            }
        } else {
            isShowingVideo = true
        }
    }
    
    private func checkForVideoPlayer() {
        guard let webView = videoWebView else { return }
        guard !hasLoadedSearch else {  // Skip check if we've already loaded search
            print("Skipping video check - already on search page")
            return
        }
        
        let checkScript = """
        var video = document.getElementsByTagName('video')[0];
        var player = document.getElementById('movie_player');
        var errorMessage = document.querySelector('.ytp-error-message') || 
                          document.querySelector('.video-unavailable-message');
        var isPlayable = false;
        
        if (video) {
            isPlayable = video.readyState >= 2;
        } else if (player) {
            var ytPlayer = window.YT && window.YT.Player ? document.querySelector('.html5-video-player') : null;
            isPlayable = ytPlayer && ytPlayer.getPlayerState && ytPlayer.getPlayerState() !== -1 && ytPlayer.getPlayerState() !== 5;
        }
        
        !(errorMessage || !isPlayable);
        """
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            webView.evaluateJavaScript(checkScript) { (result, error) in
                if let isPlayable = result as? Bool, !isPlayable {
                    print("No playable video detected, loading YouTube search in WebView")
                    self.loadYouTubeSearch(in: webView)
                } else if let error = error {
                    print("Error checking video status: \(error.localizedDescription)")
                    self.loadYouTubeSearch(in: webView)
                } else {
                    print("Playable video detected")
                }
            }
        }
    }
    
    private func loadYouTubeSearch(in webView: WKWebView) {
        let searchQuery = "\(recipe.name) \(recipe.cuisine) recipe video"
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let youtubeURL = URL(string: "https://www.youtube.com/results?search_query=\(encodedQuery)") {
            DispatchQueue.main.async {
                let request = URLRequest(url: youtubeURL)
                webView.load(request)
                self.hasLoadedSearch = true  // Set flag to prevent further checks
                print("Loaded YouTube search in WebView")
            }
        }
    }
    
    private static func googleSearchURL(for recipe: Recipe) -> URL {
        let searchQuery = "\(recipe.name) \(recipe.cuisine) recipe"
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.google.com/search?q=\(encodedQuery)")!
    }
    
    private func shareRecipe() {
        guard let url = URL(string: recipe.siteUrl) else { return }
        let textToShare = "Check out this recipe for \(recipe.name) (\(recipe.cuisine)): \(recipe.siteUrl)"
        let itemsToShare: [Any] = [textToShare, url]
        
        let activityVC = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}
