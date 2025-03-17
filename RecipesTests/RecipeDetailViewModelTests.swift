//
//  RecipeDetailViewModelTests.swift
//  RecipesTests
//
//  Created by Craig Boyce on 3/17/25.
//

import Testing
import XCTest
import WebKit
@testable import Recipes

struct RecipeDetailViewModelTests {
    
    @Test func testToggleVideoRecipe() {
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
        
        // Create a view model
        let viewModel = RecipeDetailViewModel(recipe: recipe)
        
        // Initial state should be showing recipe (not video)
        #expect(viewModel.isShowingVideo == false)
        
        // Toggle to video
        viewModel.toggleVideoRecipe()
        
        // Should now be showing video
        #expect(viewModel.isShowingVideo == true)
        
        // Toggle back to recipe
        viewModel.toggleVideoRecipe()
        
        // Should now be showing recipe again
        #expect(viewModel.isShowingVideo == false)
    }
}
