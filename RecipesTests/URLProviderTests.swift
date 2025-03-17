//
//  URLProviderTests.swift
//  RecipesTests
//
//  Created by Craig Boyce on 3/17/25.
//

import Testing
import XCTest
@testable import Recipes

struct URLProviderTests {
    
    @Test func testSearchURL() {
        // Create a test recipe
        let recipe = Recipe(
            id: "test-id",
            cuisine: "Test Cuisine",
            name: "Test Recipe",
            largePhotoUrl: "https://example.com/large.jpg",
            smallPhotoUrl: "https://example.com/small.jpg",
            siteUrl: "https://example.com/recipe",
            videoUrl: "https://www.youtube.com/watch?v=test123"
        )
        
        // Create a URLProvider
        let urlProvider = DefaultURLProvider()
        
        // Test recipe search URL
        let recipeSearchURL = urlProvider.searchURL(for: recipe, isVideoSearch: false)
        #expect(recipeSearchURL.absoluteString.contains("google.com/search"))
        #expect(recipeSearchURL.absoluteString.contains("Test%20Recipe"))
        #expect(recipeSearchURL.absoluteString.contains("Test%20Cuisine"))
        
        // Test video search URL
        let videoSearchURL = urlProvider.searchURL(for: recipe, isVideoSearch: true)
        #expect(videoSearchURL.absoluteString.contains("youtube.com/results"))
        #expect(videoSearchURL.absoluteString.contains("Test%20Recipe"))
        #expect(videoSearchURL.absoluteString.contains("Test%20Cuisine"))
        #expect(videoSearchURL.absoluteString.contains("recipe%20video"))
    }
}
