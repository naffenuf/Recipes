//
//  ContentView.swift
//  Recipes
//
//  Created by Craig Boyce on 3/6/25.
//

import SwiftUI
import UIKit
import Combine

class RecipesViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var filteredRecipes: [Recipe] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let recipeService: RecipeServiceProtocol
    
    init(recipeService: RecipeServiceProtocol = RecipeServiceFactory().makeRemoteService()) {
        self.recipeService = recipeService
        
        // Set up search text publisher to filter recipes
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.filterRecipes(searchText: searchText)
            }
            .store(in: &cancellables)
    }
    
    func loadRecipes() {
        isLoading = true
        errorMessage = nil
        
        recipeService.fetchRecipes()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] recipes in
                self?.recipes = recipes
                self?.filterRecipes()
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func refreshRecipes() async {
        // We don't set isLoading to true here because the refreshable control
        // already shows a loading indicator
        errorMessage = nil
        
        do {
            let recipes = try await fetchRecipesAsync()
            self.recipes = recipes
            self.filterRecipes()
        } catch let error as RecipeServiceError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "An unexpected error occurred"
        }
    }
    
    private func filterRecipes(searchText: String? = nil) {
        let searchQuery = searchText ?? self.searchText
        
        if searchQuery.isEmpty {
            filteredRecipes = recipes
            return
        }
        
        // Split search query into words for better matching
        let searchTerms = searchQuery.lowercased().split(separator: " ").map(String.init)
        
        filteredRecipes = recipes.filter { recipe in
            // Create a combined string of cuisine and name for searching
            let searchableText = "\(recipe.cuisine) \(recipe.name)".lowercased()
            
            // Check if all search terms are found in the searchable text
            return searchTerms.allSatisfy { term in
                searchableText.contains(term)
            }
        }
    }
    
    private func fetchRecipesAsync() async throws -> [Recipe] {
        return try await withCheckedThrowingContinuation { continuation in
            recipeService.fetchRecipes { result in
                switch result {
                case .success(let recipes):
                    continuation.resume(returning: recipes)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = RecipesViewModel()
    @State private var isIpad = UIDevice.current.userInterfaceIdiom == .pad
    
    init() {
        // Using the default initialization with factory
    }
    
    // Computed property to determine if search results are empty
    private var isSearchResultEmpty: Bool {
        return !viewModel.searchText.isEmpty && viewModel.filteredRecipes.isEmpty
    }
    
    // Computed property to determine grid columns based on device
    private var gridColumns: [GridItem] {
        // Use fixed number of columns with proper spacing
        let columns = isIpad ? 3 : 2
        // Use a larger spacing value to ensure clear separation between items
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: columns)
    }
    
    var body: some View {
        ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading recipes...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        
                        Text("Error Loading Recipes")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(errorMessage)
                            .multilineTextAlignment(.leading)
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
                } else {
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
                                    viewModel.searchText = ""
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
                            // No results view
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
                        } else if isIpad {
                            // Grid layout for iPad
                            ScrollView {
                                // Title with recipe count (centered)
                                HStack {
                                    Spacer()
                                    Text("\(viewModel.filteredRecipes.count) Recipes")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                .padding(.bottom, 8)
                                
                                LazyVGrid(columns: gridColumns, spacing: 16) {
                                    ForEach(viewModel.filteredRecipes) { recipe in
                                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                            RecipeGridItem(recipe: recipe)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                            }
                            .refreshable {
                                await viewModel.refreshRecipes()
                            }
                        } else {
                            // Grid layout for iPhone (2 columns)
                            ScrollView {
                                // Title with recipe count (centered)
                                HStack {
                                    Spacer()
                                    Text("\(viewModel.filteredRecipes.count) Recipes")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                .padding(.bottom, 8)
                                
                                LazyVGrid(columns: gridColumns, spacing: 16) {
                                    ForEach(viewModel.filteredRecipes) { recipe in
                                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                            RecipeGridItem(recipe: recipe)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                            }
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

struct RecipeRow: View {
    let recipe: Recipe
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: recipe.smallPhotoUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 60, height: 60)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure:
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .frame(width: 60, height: 60)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 60, height: 60)
            .padding(.leading, 4) // Add a bit of padding to the left of the image
            
            VStack(alignment: .leading) {
                Text(recipe.name)
                    .font(.headline)
                Text(recipe.cuisine)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 8) // Add padding between image and text
            
            Spacer()
            
            // Remove the custom chevron since NavigationLink already provides one
            // This prevents the double chevron issue
        }
        .padding(.vertical, 8)
    }
}

// Grid item for iPad and iPhone grid layout
struct RecipeGridItem: View {
    let recipe: Recipe
    
    var body: some View {
        // Card container
        VStack(spacing: 0) {
            // Recipe image
            ZStack(alignment: .bottom) {
                AsyncImage(url: URL(string: recipe.largePhotoUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                ProgressView()
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .aspectRatio(1, contentMode: .fill) // 1:1 aspect ratio (square)
                .clipped()
                
                // Text overlay with gradient background
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                    
                    Text(recipe.cuisine)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0)]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
        }
        // Card styling
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        .frame(minHeight: UIDevice.current.userInterfaceIdiom == .pad ? 170 : 150)
        .padding(6) // Add consistent padding around each grid item
    }
}

// Helper extension for Toggle binding
extension Binding {
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}

#Preview {
    ContentView()
}
