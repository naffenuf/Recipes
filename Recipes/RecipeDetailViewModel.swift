import SwiftUI
import WebKit

class RecipeDetailViewModel: ObservableObject {
    @Published var isShowingVideo = false
    @Published var videoWebView: WKWebView?
    @Published var hasLoadedSearch = false
    
    let recipe: Recipe
    let siteUrl: URL
    let videoUrl: URL?
    private let urlProvider: URLProvider
    private let navigationService: NavigationService
    
    init(recipe: Recipe,
         videoWebView: WKWebView = WKWebView(),
         urlProvider: URLProvider = DefaultURLProvider(),
         navigationService: NavigationService = DefaultNavigationService()) {
        self.recipe = recipe
        self.siteUrl = urlProvider.recipeSiteURL(from: recipe.siteUrl)
        self.videoUrl = urlProvider.videoURL(from: recipe.videoUrl)
        self.videoWebView = videoWebView
        self.urlProvider = urlProvider
        self.navigationService = navigationService
    }
    
    func toggleVideoRecipe() {
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
    
    func checkForVideoPlayer() {
        guard let webView = videoWebView else { return }
        guard !hasLoadedSearch else {
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
        let youtubeURL = urlProvider.searchURL(for: recipe)
        DispatchQueue.main.async {
            self.navigationService.loadURL(youtubeURL, in: webView)
            self.hasLoadedSearch = true
            print("Loaded YouTube search in WebView")
        }
    }
    
    func shareRecipe() -> [Any] {
        guard let url = URL(string: recipe.siteUrl) else { return [] }
        let textToShare = "Check out this recipe for \(recipe.name) (\(recipe.cuisine)): \(recipe.siteUrl)"
        return [textToShare, url]
    }
}
