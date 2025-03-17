import SwiftUI
import WebKit

struct RecipeDetailView: View {
    @ObservedObject private var viewModel: RecipeDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    
    init(recipe: Recipe,
         videoWebView: WKWebView = WKWebView(),
         urlProvider: URLProvider = DefaultURLProvider(),
         navigationService: NavigationService = DefaultNavigationService()) {
        self.viewModel = RecipeDetailViewModel(
            recipe: recipe,
            videoWebView: videoWebView,
            urlProvider: urlProvider,
            navigationService: navigationService
        )
    }
    
    var body: some View {
        ZStack {
            WebView(initialUrl: viewModel.siteUrl)
                .opacity(viewModel.isShowingVideo ? 0 : 1)
            
            if let videoUrl = viewModel.videoUrl {
                WebView(initialUrl: videoUrl,
                       onWebViewCreated: { webView in
                           DispatchQueue.main.async {
                               self.viewModel.videoWebView = webView
                           }
                       },
                       onPageLoaded: {
                           viewModel.checkForVideoPlayer()
                       },
                       disableAutoReload: true)
                .opacity(viewModel.isShowingVideo ? 1 : 0)
            }
        }
        .navigationTitle(viewModel.recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: HStack(spacing: 20) {
            if viewModel.videoUrl != nil {
                Button(action: viewModel.toggleVideoRecipe) {
                    Image(systemName: viewModel.isShowingVideo ? "doc.text" : "play.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                }
                .help(viewModel.isShowingVideo ? "View Recipe Directions" : "Watch Recipe Video")
            }
            
            Button(action: shareRecipe) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
            }
        })
    }
    
    private func shareRecipe() {
        let itemsToShare = viewModel.shareRecipe()
        let activityVC = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}
