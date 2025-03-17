import SwiftUI
import UIKit
import Combine

struct ContentView: View {
    @StateObject private var viewModel: RecipesViewModel
    private let deviceInfo: DeviceInfo
    
    init(viewModel: RecipesViewModel = RecipesViewModel(),
         deviceInfo: DeviceInfo = DefaultDeviceInfo()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.deviceInfo = deviceInfo
    }
    
    private var isSearchResultEmpty: Bool {
        !viewModel.searchText.isEmpty && viewModel.filteredRecipes.isEmpty
    }
    
    var body: some View {
        ZStack {
            switch viewModel.viewState {
            case .loading:
                ProgressView("Loading recipes...")
                    .progressViewStyle(CircularProgressViewStyle())
                
            case .error(let message):
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("Error Loading Recipes")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(message)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Try Again") {
                        viewModel.loadRecipes()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                
            case .success:
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search recipes...", text: $viewModel.searchText)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        if !viewModel.searchText.isEmpty {
                            Button(action: {
                                viewModel.updateSearchText("")
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    if isSearchResultEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("No recipes found")
                                .font(.headline)
                            
                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        RecipeGridView(recipes: viewModel.filteredRecipes, isIpad: deviceInfo.isIpad)
                            .refreshable {
                                await viewModel.refreshRecipes()
                            }
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadRecipes()
        }
    }
}

// Unchanged: RecipeRow, RecipeGridItem, and Binding extension (defined in separate files)
// No import statements needed for these
