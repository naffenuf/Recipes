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
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let recipeService: RecipeServiceProtocol
    
    init(recipeService: RecipeServiceProtocol = RecipeServiceFactory().makeRemoteService()) {
        self.recipeService = recipeService
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
        } catch let error as RecipeServiceError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "An unexpected error occurred"
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
                    List(viewModel.recipes) { recipe in
                        RecipeRow(recipe: recipe)
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await viewModel.refreshRecipes()
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
            
            VStack(alignment: .leading) {
                Text(recipe.name)
                    .font(.headline)
                Text(recipe.cuisine)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
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
