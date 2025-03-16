//
//  RecipeDetailViewTests.swift
//  RecipesTests
//
//  Created by Craig Boyce on 3/16/25.
//

import Testing
import XCTest
import SwiftUI
@testable import Recipes

struct RecipeDetailViewTests {
    
    @Test func testHandleWebViewError404() {
        // Given a recipe and a detail view
        let recipe = Recipe(
            id: "test-id",
            cuisine: "Test Cuisine",
            name: "Test Recipe",
            largePhotoUrl: "https://example.com/large.jpg",
            smallPhotoUrl: "https://example.com/small.jpg",
            siteUrl: "https://example.com/recipe",
            videoUrl: "https://www.youtube.com/watch?v=test"
        )
        
        let viewModel = RecipeDetailViewModel(recipe: recipe)
        
        // When a 404 error occurs
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorFileDoesNotExist, userInfo: nil)
        let response = HTTPURLResponse(url: URL(string: "https://example.com/recipe")!, statusCode: 404, httpVersion: nil, headerFields: nil)
        
        viewModel.handleWebViewError(error, response: response)
        
        // Then the web view should be hidden and error message shown
        #expect(viewModel.showWebView == false)
        #expect(viewModel.showError == true)
        #expect(viewModel.errorMessage.contains("couldn't be found"))
    }
    
    @Test func testHandleConnectionError() {
        // Given a recipe and a detail view
        let recipe = Recipe(
            id: "test-id",
            cuisine: "Test Cuisine",
            name: "Test Recipe",
            largePhotoUrl: "https://example.com/large.jpg",
            smallPhotoUrl: "https://example.com/small.jpg",
            siteUrl: "https://example.com/recipe",
            videoUrl: "https://www.youtube.com/watch?v=test"
        )
        
        let viewModel = RecipeDetailViewModel(recipe: recipe)
        
        // When a connection error occurs
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil)
        
        viewModel.handleWebViewError(error, response: nil)
        
        // Then the web view should be hidden and error message shown
        #expect(viewModel.showWebView == false)
        #expect(viewModel.showError == true)
        #expect(viewModel.errorMessage.contains("couldn't be found"))
    }
    
    @Test func testYouTubeSearchFormatting() {
        // Given a recipe with special characters in the name
        let recipe = Recipe(
            id: "test-id",
            cuisine: "British",
            name: "Apple & Blackberry Crumble",
            largePhotoUrl: "https://example.com/large.jpg",
            smallPhotoUrl: "https://example.com/small.jpg",
            siteUrl: "https://example.com/recipe",
            videoUrl: "https://www.youtube.com/watch?v=test"
        )
        
        let viewModel = RecipeDetailViewModel(recipe: recipe)
        
        // When creating a YouTube search query
        let searchQuery = viewModel.createYouTubeSearchQuery()
        
        // Then it should properly format the recipe name and replace & with "and"
        #expect(searchQuery.contains("Apple and Blackberry Crumble"))
        #expect(searchQuery.contains("British"))
        #expect(!searchQuery.contains("&"))
    }
}

// View model for testing
class RecipeDetailViewModel {
    let recipe: Recipe
    var showWebView = true
    var showError = false
    var errorMessage = ""
    
    init(recipe: Recipe) {
        self.recipe = recipe
    }
    
    func handleWebViewError(_ error: Error, response: HTTPURLResponse?) {
        // Check if it's a 404 error
        let is404 = response?.statusCode == 404
        let isConnectionError = (error as NSError).domain == NSURLErrorDomain &&
                               ((error as NSError).code == NSURLErrorCannotFindHost ||
                                (error as NSError).code == NSURLErrorCannotConnectToHost)
        
        if is404 || isConnectionError {
            // If we have a video URL, go directly to it
            if !recipe.videoUrl.isEmpty {
                errorMessage = "The recipe page couldn't be found. Opening the video instead."
                showWebView = false
                showError = true
            } else {
                // No video, show error and YouTube search option
                errorMessage = "The recipe page couldn't be found. Would you like to search for it on YouTube?"
                showWebView = false
                showError = true
            }
        } else {
            // Other errors
            errorMessage = "There was a problem loading the recipe: \(error.localizedDescription)"
            showWebView = false
            showError = true
        }
    }
    
    func createYouTubeSearchQuery() -> String {
        let fullRecipeName = recipe.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let fullCuisineName = recipe.cuisine.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle special characters like & in recipe names
        let processedName = fullRecipeName.replacingOccurrences(of: "&", with: "and")
        
        return "\(processedName) \(fullCuisineName) recipe how to make"
    }
}
