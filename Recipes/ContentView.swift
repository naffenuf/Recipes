//
//  ContentView.swift
//  Recipes
//
//  Created by Craig Boyce on 3/6/25.
//

import SwiftUI
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
    
    init() {
        // Using the default initialization with factory
    }
    
    // Computed property to determine if search results are empty
    private var isSearchResultEmpty: Bool {
        return !viewModel.searchText.isEmpty && viewModel.filteredRecipes.isEmpty
    }
    
    var body: some View {
        NavigationView {
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
                        } else {
                            // Recipe list
                            List(viewModel.filteredRecipes) { recipe in
                                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                    RecipeRow(recipe: recipe)
                                }
                                // Add horizontal padding on both sides
                                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            }
                            .listStyle(PlainListStyle())
                            // Make separators edge-to-edge
                            .environment(\.defaultMinListRowHeight, 1)
                            .refreshable {
                                await viewModel.refreshRecipes()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Recipes")
        }
        .onAppear {
            viewModel.loadRecipes()
        }
    }
}

struct RecipeRow: View {
    let recipe: Recipe
    
    var body: some View {
        HStack(spacing: 12) { // Add spacing between image and text
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
            
            VStack(alignment: .leading, spacing: 4) { // Add spacing between title and subtitle
                Text(recipe.name)
                    .font(.headline)
                Text(recipe.cuisine)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Remove the custom chevron since NavigationLink already provides one
            // This prevents the double chevron issue
        }
        .padding(.vertical, 12) // Increase vertical padding
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
