//
//  RecipesTests.swift
//  RecipesTests
//
//  Created by Craig Boyce on 3/6/25.
//

import Testing
import XCTest
@testable import Recipes

struct RecipeDTOTests {
    
    @Test func testValidRecipeDTO() throws {
        // Given a valid recipe DTO
        let recipeDTO = RecipeDTO(
            uuid: "eed6005f-f8c8-451f-98d0-4088e2b40eb6",
            cuisine: "British",
            name: "Bakewell Tart",
            photo_url_large: "https://some.url/large.jpg",
            photo_url_small: "https://some.url/small.jpg",
            source_url: "https://some.url/index.html",
            youtube_url: "https://www.youtube.com/watch?v=some.id"
        )
        
        // When validating the recipe
        let recipe = try recipeDTO.validate()
        
        // Then it should convert to a valid Recipe domain model
        #expect(recipe.id == "eed6005f-f8c8-451f-98d0-4088e2b40eb6")
        #expect(recipe.cuisine == "British")
        #expect(recipe.name == "Bakewell Tart")
        #expect(recipe.largePhotoUrl == "https://some.url/large.jpg")
        #expect(recipe.smallPhotoUrl == "https://some.url/small.jpg")
        #expect(recipe.siteUrl == "https://some.url/index.html")
        #expect(recipe.videoUrl == "https://www.youtube.com/watch?v=some.id")
    }
    
    @Test func testRecipeDTOWithInvalidUUID() throws {
        // Given a recipe DTO with an invalid UUID
        let recipeDTO = RecipeDTO(
            uuid: "invalid-uuid",
            cuisine: "British",
            name: "Bakewell Tart",
            photo_url_large: "https://some.url/large.jpg",
            photo_url_small: "https://some.url/small.jpg",
            source_url: "https://some.url/index.html",
            youtube_url: "https://www.youtube.com/watch?v=some.id"
        )
        
        // When validating the recipe, it should throw an error
        do {
            _ = try recipeDTO.validate()
            XCTFail("Expected validation to fail with invalid UUID")
        } catch let error as RecipeValidationError {
            // Then it should throw a validation error
            if case .invalidRecipe(let message) = error {
                #expect(message.contains("Invalid UUID"))
            } else {
                XCTFail("Expected invalidRecipe error")
            }
        } catch {
            XCTFail("Expected RecipeValidationError")
        }
    }
    
    @Test func testRecipeDTOWithEmptyCuisine() throws {
        // Given a recipe DTO with an empty cuisine
        let recipeDTO = RecipeDTO(
            uuid: "eed6005f-f8c8-451f-98d0-4088e2b40eb6",
            cuisine: "",
            name: "Bakewell Tart",
            photo_url_large: "https://some.url/large.jpg",
            photo_url_small: "https://some.url/small.jpg",
            source_url: "https://some.url/index.html",
            youtube_url: "https://www.youtube.com/watch?v=some.id"
        )
        
        // When validating the recipe, it should throw an error
        do {
            _ = try recipeDTO.validate()
            XCTFail("Expected validation to fail with empty cuisine")
        } catch let error as RecipeValidationError {
            // Then it should throw a validation error
            if case .invalidRecipe(let message) = error {
                #expect(message.contains("Cuisine cannot be empty"))
            } else {
                XCTFail("Expected invalidRecipe error")
            }
        } catch {
            XCTFail("Expected RecipeValidationError")
        }
    }
    
    @Test func testRecipeDTOWithEmptyName() throws {
        // Given a recipe DTO with an empty name
        let recipeDTO = RecipeDTO(
            uuid: "eed6005f-f8c8-451f-98d0-4088e2b40eb6",
            cuisine: "British",
            name: "",
            photo_url_large: "https://some.url/large.jpg",
            photo_url_small: "https://some.url/small.jpg",
            source_url: "https://some.url/index.html",
            youtube_url: "https://www.youtube.com/watch?v=some.id"
        )
        
        // When validating the recipe, it should throw an error
        do {
            _ = try recipeDTO.validate()
            XCTFail("Expected validation to fail with empty name")
        } catch let error as RecipeValidationError {
            // Then it should throw a validation error
            if case .invalidRecipe(let message) = error {
                #expect(message.contains("Name cannot be empty"))
            } else {
                XCTFail("Expected invalidRecipe error")
            }
        } catch {
            XCTFail("Expected RecipeValidationError")
        }
    }
    
    @Test func testRecipeDTOWithInvalidPhotoURL() throws {
        // Given a recipe DTO with an invalid photo URL
        let recipeDTO = RecipeDTO(
            uuid: "eed6005f-f8c8-451f-98d0-4088e2b40eb6",
            cuisine: "British",
            name: "Bakewell Tart",
            photo_url_large: "invalid-url",
            photo_url_small: "https://some.url/small.jpg",
            source_url: "https://some.url/index.html",
            youtube_url: "https://www.youtube.com/watch?v=some.id"
        )
        
        // When validating the recipe, it should throw an error
        do {
            _ = try recipeDTO.validate()
            XCTFail("Expected validation to fail with invalid photo URL")
        } catch let error as RecipeValidationError {
            // Then it should throw a validation error
            if case .invalidRecipe(let message) = error {
                #expect(message.contains("Invalid large photo URL"))
            } else {
                XCTFail("Expected invalidRecipe error")
            }
        } catch {
            XCTFail("Expected RecipeValidationError")
        }
    }
}

struct RecipesDTOTests {
    
    @Test func testValidRecipesDTO() throws {
        // Given a valid recipes DTO with multiple recipes
        let recipesDTO = RecipesDTO(recipes: [
            RecipeDTO(
                uuid: "eed6005f-f8c8-451f-98d0-4088e2b40eb6",
                cuisine: "British",
                name: "Bakewell Tart",
                photo_url_large: "https://some.url/large.jpg",
                photo_url_small: "https://some.url/small.jpg",
                source_url: "https://some.url/index.html",
                youtube_url: "https://www.youtube.com/watch?v=some.id"
            ),
            RecipeDTO(
                uuid: "f8c8-451f-98d0-4088e2b40eb6-eed6005f",
                cuisine: "Italian",
                name: "Tiramisu",
                photo_url_large: "https://some.url/large2.jpg",
                photo_url_small: "https://some.url/small2.jpg",
                source_url: "https://some.url/index2.html",
                youtube_url: "https://www.youtube.com/watch?v=some.id2"
            )
        ])
        
        // When validating the recipes
        let recipes = try recipesDTO.validate()
        
        // Then it should convert to valid Recipe domain models
        #expect(recipes.count == 2)
        #expect(recipes[0].name == "Bakewell Tart")
        #expect(recipes[1].name == "Tiramisu")
    }
    
    @Test func testEmptyRecipesDTO() throws {
        // Given an empty recipes DTO
        let recipesDTO = RecipesDTO(recipes: [])
        
        // When validating the recipes, it should throw an error
        do {
            _ = try recipesDTO.validate()
            XCTFail("Expected validation to fail with empty recipes")
        } catch let error as RecipeValidationError {
            // Then it should throw a validation error
            if case .invalidRecipesList(let message) = error {
                #expect(message.contains("No recipes found"))
            } else {
                XCTFail("Expected invalidRecipesList error")
            }
        } catch {
            XCTFail("Expected RecipeValidationError")
        }
    }
    
    @Test func testRecipesDTOWithInvalidRecipe() throws {
        // Given a recipes DTO with one valid and one invalid recipe
        let recipesDTO = RecipesDTO(recipes: [
            RecipeDTO(
                uuid: "eed6005f-f8c8-451f-98d0-4088e2b40eb6",
                cuisine: "British",
                name: "Bakewell Tart",
                photo_url_large: "https://some.url/large.jpg",
                photo_url_small: "https://some.url/small.jpg",
                source_url: "https://some.url/index.html",
                youtube_url: "https://www.youtube.com/watch?v=some.id"
            ),
            RecipeDTO(
                uuid: "invalid-uuid",  // Invalid UUID
                cuisine: "Italian",
                name: "Tiramisu",
                photo_url_large: "https://some.url/large2.jpg",
                photo_url_small: "https://some.url/small2.jpg",
                source_url: "https://some.url/index2.html",
                youtube_url: "https://www.youtube.com/watch?v=some.id2"
            )
        ])
        
        // When validating the recipes, it should throw an error
        do {
            _ = try recipesDTO.validate()
            XCTFail("Expected validation to fail with invalid recipe")
        } catch let error as RecipeValidationError {
            // Then it should throw a validation error
            if case .invalidRecipesList(let message) = error {
                #expect(message.contains("Invalid recipe found"))
            } else {
                XCTFail("Expected invalidRecipesList error")
            }
        } catch {
            XCTFail("Expected RecipeValidationError")
        }
    }
}
