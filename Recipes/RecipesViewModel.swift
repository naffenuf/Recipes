import SwiftUI
import Combine

class RecipesViewModel: ObservableObject {
    enum ViewState {
        case loading
        case success
        case error(String)
    }
    
    @Published var viewState: ViewState = .loading
    @Published var filteredRecipes: [Recipe] = []
    private var recipes: [Recipe] = []
    @Published var searchText: String = ""
    private var cancellables = Set<AnyCancellable>()
    private let recipeService: RecipeServiceProtocol
    
    init(recipeService: RecipeServiceProtocol = RecipeServiceFactory().makeRemoteService()) {
        self.recipeService = recipeService
        
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.filterRecipes(searchText: searchText)
            }
            .store(in: &cancellables)
    }
    
    func updateSearchText(_ text: String) {
        searchText = text
    }
    
    func loadRecipes() {
        viewState = .loading
        
        recipeService.fetchRecipes()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.viewState = .error(error.localizedDescription)
                }
            } receiveValue: { [weak self] recipes in
                self?.recipes = recipes
                self?.filterRecipes()
                self?.viewState = .success
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func refreshRecipes() async {
        viewState = .loading
        
        do {
            let recipes = try await fetchRecipesAsync()
            self.recipes = recipes
            self.filterRecipes()
            self.viewState = .success
        } catch let error as RecipeServiceError {
            viewState = .error(error.localizedDescription)
        } catch {
            viewState = .error("An unexpected error occurred")
        }
    }
    
    private func filterRecipes(searchText: String? = nil) {
        let searchQuery = searchText ?? self.searchText
        
        if searchQuery.isEmpty {
            filteredRecipes = recipes
            return
        }
        
        let searchTerms = searchQuery.lowercased().split(separator: " ").map(String.init)
        filteredRecipes = recipes.filter { recipe in
            let searchableText = "\(recipe.cuisine) \(recipe.name)".lowercased()
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
