//
//  RecipeDto.swift
//  Recipes
//
//  Created by Craig Boyce on 3/10/25.
//

import Foundation

// Error types for recipe validation
enum RecipeValidationError: Error {
    case invalidRecipe(String)
    case invalidRecipesList(String)
}

// Top-level DTO for the recipes JSON
struct RecipesDTO: Decodable {
    let recipes: [RecipeDTO]
    
    // Validate the entire recipes list
    func validate() throws -> [Recipe] {
        // Check if the recipes array is empty
        guard !recipes.isEmpty else {
            throw RecipeValidationError.invalidRecipesList("No recipes found in the data")
        }
        
        // Try to convert all recipes, if any fails, throw an error
        do {
            return try recipes.map { try $0.validate() }
        } catch let error as RecipeValidationError {
            throw RecipeValidationError.invalidRecipesList("Invalid recipe found: \(error)")
        } catch {
            throw RecipeValidationError.invalidRecipesList("Unknown error during validation: \(error)")
        }
    }
}

// DTO for individual recipe
struct RecipeDTO: Decodable {
    let uuid: String
    let cuisine: String
    let name: String
    let photo_url_large: String
    let photo_url_small: String
    let source_url: String?
    let youtube_url: String?
    
    // Validate an individual recipe
    func validate() throws -> Recipe {
        // Validate UUID
        guard !uuid.isEmpty, UUID(uuidString: uuid) != nil else {
            throw RecipeValidationError.invalidRecipe("Invalid UUID: \(uuid)")
        }
        
        // Validate required fields are not empty
        guard !cuisine.isEmpty else {
            throw RecipeValidationError.invalidRecipe("Cuisine cannot be empty")
        }
        
        guard !name.isEmpty else {
            throw RecipeValidationError.invalidRecipe("Name cannot be empty")
        }
        
        guard !photo_url_large.isEmpty, URL(string: photo_url_large) != nil else {
            throw RecipeValidationError.invalidRecipe("Invalid large photo URL")
        }
        
        guard !photo_url_small.isEmpty, URL(string: photo_url_small) != nil else {
            throw RecipeValidationError.invalidRecipe("Invalid small photo URL")
        }
        
        // Convert to domain model
        return Recipe(
            id: uuid,
            cuisine: cuisine,
            name: name,
            largePhotoUrl: photo_url_large,
            smallPhotoUrl: photo_url_small,
            siteUrl: source_url ?? "",
            videoUrl: youtube_url ?? ""
        )
    }
}
