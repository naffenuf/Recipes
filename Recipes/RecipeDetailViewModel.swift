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
        self.siteUrl = urlProvider.recipeSiteURL(from: recipe.siteUrl, for: recipe)
        self.videoUrl = urlProvider.videoURL(from: recipe.videoUrl, for: recipe)
        self.videoWebView = videoWebView
        self.urlProvider = urlProvider
        self.navigationService = navigationService
        print("Initialized with siteUrl: \(siteUrl.absoluteString), videoUrl: \(String(describing: videoUrl?.absoluteString))")
    }
    
    func toggleVideoRecipe() {
        if isShowingVideo {
            // Switching from video to directions
            if let webView = videoWebView {
                let pauseScript = """
                var player = document.getElementsByTagName('video')[0] || document.getElementById('movie_player');
                if (player) {
                    if (player.pause) player.pause();
                    else if (player.pauseVideo) player.pauseVideo();
                }
                """
                DispatchQueue.main.async {
                    webView.evaluateJavaScript(pauseScript) { (result, error) in
                        if let error = error {
                            print("Error pausing video: \(error.localizedDescription)")
                        } else {
                            print("Video paused successfully")
                        }
                        self.isShowingVideo = false
                    }
                }
            } else {
                isShowingVideo = false
            }
        } else {
            // Switching from directions to video
            isShowingVideo = true
            print("Returning to video WebView, should be paused at current position")
            // No reload needed; the WebView should preserve its state
        }
    }
    
    func checkForVideoPlayer() {
        guard let webView = videoWebView else {
            print("No WebView available to check for video")
            return
        }
        guard !hasLoadedSearch else {
            print("Skipping video check - already on search page")
            return
        }
        
        let checkScript = """
        var errorElements = document.querySelectorAll('.ytp-error, .ytp-error-content, .video-unavailable-message, [aria-label*="unavailable"], [aria-label*="removed"]');
        var isError = errorElements.length > 0 || 
                     document.body.innerText.toLowerCase().includes('unavailable') || 
                     document.body.innerText.toLowerCase().includes('removed') || 
                     document.body.innerText.toLowerCase().includes('this video is not available') || 
                     document.body.innerText.toLowerCase().includes('video unavailable') || 
                     document.body.innerText.toLowerCase().includes('video is unavailable') || 
                     document.title.toLowerCase().includes('unavailable') || 
                     document.title.toLowerCase().includes('removed');
        var video = document.getElementsByTagName('video')[0];
        var player = document.getElementById('movie_player');
        var isPlayable = false;
        
        if (video) {
            isPlayable = video.readyState >= 2 && !isError;
        } else if (player) {
            var ytPlayer = document.querySelector('.html5-video-player');
            isPlayable = ytPlayer && ytPlayer.getPlayerState && ytPlayer.getPlayerState() !== -1 && ytPlayer.getPlayerState() !== 5 && !isError;
        }
        
        !isError && isPlayable;
        """
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            print("Checking video playability for URL: \(String(describing: webView.url?.absoluteString))")
            webView.evaluateJavaScript(checkScript) { (result, error) in
                if let error = error {
                    print("Error evaluating JavaScript: \(error.localizedDescription)")
                    self.loadYouTubeSearch(in: webView)
                    return
                }
                if let isPlayable = result as? Bool {
                    print("Video playability result: \(isPlayable)")
                    if !isPlayable {
                        print("No playable video detected, loading YouTube search in WebView")
                        self.loadYouTubeSearch(in: webView)
                    } else {
                        print("Video is playable")
                    }
                } else {
                    print("Unexpected JavaScript result: \(String(describing: result))")
                    self.loadYouTubeSearch(in: webView)
                }
            }
        }
    }
    
    private func loadYouTubeSearch(in webView: WKWebView) {
        let youtubeURL = urlProvider.searchURL(for: recipe, isVideoSearch: true)
        print("Loading YouTube search URL: \(youtubeURL.absoluteString)")
        DispatchQueue.main.async {
            self.navigationService.loadURL(youtubeURL, in: webView)
            self.hasLoadedSearch = true
        }
    }
    
    func shareRecipe() -> [Any] {
        guard let url = URL(string: recipe.siteUrl) else { return [] }
        let textToShare = "Check out this recipe for \(recipe.name) (\(recipe.cuisine)): \(recipe.siteUrl)"
        return [textToShare, url]
    }
}
