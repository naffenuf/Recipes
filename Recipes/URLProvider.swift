//
//  URLProvider.swift
//  Recipes
//
//  Created by Craig Boyce on 3/17/25.
//

import Foundation

protocol URLProvider {
    func recipeSiteURL(from string: String) -> URL
    func videoURL(from string: String) -> URL?
    func searchURL(for recipe: Recipe) -> URL
}

class DefaultURLProvider: URLProvider {
    func recipeSiteURL(from string: String) -> URL {
        URL(string: string) ?? googleSearchURL(for: string)
    }
    
    func videoURL(from string: String) -> URL? {
        !string.isEmpty ? URL(string: string) ?? youtubeSearchURL(for: string) : nil
    }
    
    func searchURL(for recipe: Recipe) -> URL {
        let searchQuery = "\(recipe.name) \(recipe.cuisine) recipe video"
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.youtube.com/results?search_query=\(encodedQuery)")!
    }
    
    private func youtubeSearchURL(for string: String) -> URL {
        let searchQuery = string // Could improve with better parsing
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.youtube.com/results?search_query=\(encodedQuery)")!
    }
    
    private func googleSearchURL(for string: String) -> URL {
        let searchQuery = string
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.google.com/search?q=\(encodedQuery)")!
    }
}
