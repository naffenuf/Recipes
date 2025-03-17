import Foundation

protocol URLProvider {
    func recipeSiteURL(from string: String, for recipe: Recipe) -> URL
    func videoURL(from string: String, for recipe: Recipe) -> URL?
    func searchURL(for recipe: Recipe, isVideoSearch: Bool) -> URL
}

class DefaultURLProvider: URLProvider {
    func recipeSiteURL(from string: String, for recipe: Recipe) -> URL {
        if let url = URL(string: string) {
            return url
        }
        let fallbackURL = searchURL(for: recipe, isVideoSearch: false)
        print("Falling back to Google search URL: \(fallbackURL.absoluteString)")
        return fallbackURL
    }
    
    func videoURL(from string: String, for recipe: Recipe) -> URL? {
        guard !string.isEmpty else { return nil }
        if let url = URL(string: string) {
            return url
        }
        let fallbackURL = searchURL(for: recipe, isVideoSearch: true)
        print("Falling back to YouTube search URL: \(fallbackURL.absoluteString)")
        return fallbackURL
    }
    
    func searchURL(for recipe: Recipe, isVideoSearch: Bool) -> URL {
        let searchQuery = "\(recipe.name) \(recipe.cuisine) \(isVideoSearch ? "recipe video" : "recipe")"
        // Use a stricter encoding for the query
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~ ")) ?? ""
        let baseURL = isVideoSearch ? "https://www.youtube.com/results?search_query=" : "https://www.google.com/search?q="
        guard let url = URL(string: "\(baseURL)\(encodedQuery)") else {
            print("Failed to create URL for query: \(searchQuery)")
            // Fallback to a default search URL
            return URL(string: isVideoSearch ? "https://www.youtube.com/results?search_query=recipe+video" : "https://www.google.com/search?q=recipe")!
        }
        return url
    }
}
