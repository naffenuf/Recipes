//
//  RecipeServiceTests.swift
//  RecipesTests
//
//  Created by Craig Boyce on 3/16/25.
//

import Testing
import XCTest
import Combine
@testable import Recipes

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler is unavailable.")
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
}

struct RecipeServiceTests {
    
    var cancellables = Set<AnyCancellable>()
    
    @Test func testFetchRecipesSuccess() async throws {
        // Given a valid recipe DTO
        let validRecipeDTO = RecipeDTO(
            uuid: "eed6005f-f8c8-451f-98d0-4088e2b40eb6",
            cuisine: "British",
            name: "Bakewell Tart",
            photo_url_large: "https://some.url/large.jpg",
            photo_url_small: "https://some.url/small.jpg",
            source_url: "https://some.url/index.html",
            youtube_url: "https://www.youtube.com/watch?v=some.id"
        )
        let recipesDTO = RecipesDTO(recipes: [validRecipeDTO])
        
        // Create a mock data source that returns the valid recipes
        let mockDataSource = MockRecipeDataSource(recipesDTO: recipesDTO)
        let service = RecipeService(dataSource: mockDataSource)
        
        // When fetching recipes
        let expectation = XCTestExpectation(description: "Fetch recipes")
        
        service.fetchRecipes { result in
            switch result {
            case .success(let recipes):
                // Then it should return valid recipes
                #expect(recipes.count == 1)
                #expect(recipes[0].name == "Bakewell Tart")
                #expect(recipes[0].cuisine == "British")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
        }
        
        await XCTWaiter.wait(for: [expectation], timeout: 1.0)
    }
    
    @Test func testFetchRecipesWithInvalidRecipe() async throws {
        // Given a recipe DTO with an invalid UUID
        let invalidRecipeDTO = RecipeDTO(
            uuid: "invalid-uuid",
            cuisine: "British",
            name: "Bakewell Tart",
            photo_url_large: "https://some.url/large.jpg",
            photo_url_small: "https://some.url/small.jpg",
            source_url: "https://some.url/index.html",
            youtube_url: "https://www.youtube.com/watch?v=some.id"
        )
        let recipesDTO = RecipesDTO(recipes: [invalidRecipeDTO])
        
        // Create a mock data source that returns the invalid recipe
        let mockDataSource = MockRecipeDataSource(recipesDTO: recipesDTO)
        let service = RecipeService(dataSource: mockDataSource)
        
        // When fetching recipes
        let expectation = XCTestExpectation(description: "Fetch recipes with validation error")
        
        service.fetchRecipes { result in
            switch result {
            case .success:
                XCTFail("Expected validation error but got success")
            case .failure(let error):
                // Then it should return a validation error
                if case .validationError = error {
                    // Just check that we got a validation error, don't check the specific message
                    expectation.fulfill()
                } else {
                    XCTFail("Expected validationError but got \(error)")
                }
            }
        }
        
        await XCTWaiter.wait(for: [expectation], timeout: 1.0)
    }
    
    @Test func testFetchRecipesWithEmptyList() async throws {
        // Given an empty recipes DTO
        let recipesDTO = RecipesDTO(recipes: [])
        
        // Create a mock data source that returns empty recipes
        let mockDataSource = MockRecipeDataSource(recipesDTO: recipesDTO)
        let service = RecipeService(dataSource: mockDataSource)
        
        // When fetching recipes
        let expectation = XCTestExpectation(description: "Fetch recipes with empty list")
        
        service.fetchRecipes { result in
            switch result {
            case .success:
                XCTFail("Expected validation error but got success")
            case .failure(let error):
                // Then it should return a validation error
                if case .validationError = error {
                    // Just check that we got a validation error, don't check the specific message
                    expectation.fulfill()
                } else {
                    XCTFail("Expected validationError but got \(error)")
                }
            }
        }
        
        await XCTWaiter.wait(for: [expectation], timeout: 1.0)
    }
    
    @Test func testFetchRecipesWithNetworkError() async throws {
        // Given a mock data source that returns an error
        let networkError = NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Network connection failed"])
        let mockDataSource = MockRecipeDataSource(error: networkError)
        let service = RecipeService(dataSource: mockDataSource)
        
        // When fetching recipes
        let expectation = XCTestExpectation(description: "Fetch recipes with network error")
        
        service.fetchRecipes { result in
            switch result {
            case .success:
                XCTFail("Expected network error but got success")
            case .failure(let error):
                // Then it should return a network error
                if case .networkError = error {
                    // Just check that we got a network error, don't check the specific message
                    expectation.fulfill()
                } else {
                    XCTFail("Expected networkError but got \(error)")
                }
            }
        }
        
        await XCTWaiter.wait(for: [expectation], timeout: 1.0)
    }
    
    @Test mutating func testFetchRecipesWithCombine() async throws {
        // Given a valid recipe DTO
        let validRecipeDTO = RecipeDTO(
            uuid: "eed6005f-f8c8-451f-98d0-4088e2b40eb6",
            cuisine: "British",
            name: "Bakewell Tart",
            photo_url_large: "https://some.url/large.jpg",
            photo_url_small: "https://some.url/small.jpg",
            source_url: "https://some.url/index.html",
            youtube_url: "https://www.youtube.com/watch?v=some.id"
        )
        let recipesDTO = RecipesDTO(recipes: [validRecipeDTO])
        
        // Create a mock data source that returns the valid recipes
        let mockDataSource = MockRecipeDataSource(recipesDTO: recipesDTO)
        let service = RecipeService(dataSource: mockDataSource)
        
        // When fetching recipes using Combine
        let expectation = XCTestExpectation(description: "Fetch recipes with Combine")
        
        service.fetchRecipes()
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success but got error: \(error)")
                }
            }, receiveValue: { recipes in
                // Then it should return valid recipes
                #expect(recipes.count == 1)
                #expect(recipes[0].name == "Bakewell Tart")
                #expect(recipes[0].cuisine == "British")
                expectation.fulfill()
            })
            .store(in: &cancellables)
        
        await XCTWaiter.wait(for: [expectation], timeout: 1.0)
    }
    
    @Test func testLocalDataSource() async throws {
        // This test requires the recipes.json file to be in the test bundle
        // For a real test, you would create a test bundle with a test recipes.json file
        // Here we're just testing the factory method
        let factory = RecipeServiceFactory()
        let service = factory.makeLocalService()
        #expect(service is RecipeService)
        
        // Test static method for backward compatibility
        let staticService = RecipeServiceFactory.makeLocalService()
        #expect(staticService is RecipeService)
    }
    
    @Test func testRemoteDataSource() async throws {
        // Test the factory method for creating a remote service
        let factory = RecipeServiceFactory()
        let service = factory.makeRemoteService()
        #expect(service is RecipeService)
        
        // Test static method for backward compatibility
        let staticService = RecipeServiceFactory.makeRemoteService()
        #expect(staticService is RecipeService)
    }
}
