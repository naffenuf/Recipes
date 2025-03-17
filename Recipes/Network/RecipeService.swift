//
//  RecipeService.swift
//  Recipes
//
//  Created by Craig Boyce on 3/8/25.
//

import Foundation
import Combine

/// Service errors for recipe operations
enum RecipeServiceError: Error, Equatable {
    case networkError(String)
    case decodingError(String)
    case validationError(String)
    
    static func == (lhs: RecipeServiceError, rhs: RecipeServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.networkError(let lhsMessage), .networkError(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.decodingError(let lhsMessage), .decodingError(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.validationError(let lhsMessage), .validationError(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

protocol RecipeServiceProtocol {
    func fetchRecipes() -> AnyPublisher<[Recipe], RecipeServiceError>
    func fetchRecipes(completion: @escaping (Result<[Recipe], RecipeServiceError>) -> Void)
}

/// Factory for creating recipe services with different data sources
class RecipeServiceFactory {
    private let defaultBundle: Bundle
    private let defaultFilename: String
    private let defaultSession: URLSession
    private let defaultEndpoint: URL
    
    init(
        defaultBundle: Bundle = .main,
        defaultFilename: String = "recipes",
        defaultSession: URLSession = .shared,
        defaultEndpoint: URL = URL(string: "https://d3jbb8n5wk0qxi.cloudfront.net/recipes.json")!
    ) {
        self.defaultBundle = defaultBundle
        self.defaultFilename = defaultFilename
        self.defaultSession = defaultSession
        self.defaultEndpoint = defaultEndpoint
    }
    
    /// Create a service that uses the local JSON file
    func makeLocalService(bundle: Bundle? = nil, filename: String? = nil) -> RecipeServiceProtocol {
        let dataSource = LocalRecipeDataSource(
            bundle: bundle ?? defaultBundle,
            filename: filename ?? defaultFilename
        )
        return RecipeService(dataSource: dataSource)
    }
    
    /// Create a service that uses the remote endpoint
    func makeRemoteService(session: URLSession? = nil, endpoint: URL? = nil) -> RecipeServiceProtocol {
        let dataSource = RemoteRecipeDataSource(
            session: session ?? defaultSession,
            endpoint: endpoint ?? defaultEndpoint
        )
        return RecipeService(dataSource: dataSource)
    }
    
    /// Create a mock service for testing
    func makeMockService(recipesDTO: RecipesDTO = RecipesDTO(recipes: []), error: Error? = nil) -> RecipeServiceProtocol {
        let dataSource = MockRecipeDataSource(recipesDTO: recipesDTO, error: error)
        return RecipeService(dataSource: dataSource)
    }
    
    // Static methods for backward compatibility
    
    /// Create a service that uses the local JSON file
    static func makeLocalService(bundle: Bundle = .main, filename: String = "recipes") -> RecipeServiceProtocol {
        let factory = RecipeServiceFactory()
        return factory.makeLocalService(bundle: bundle, filename: filename)
    }
    
    /// Create a service that uses the remote endpoint
    static func makeRemoteService(session: URLSession = .shared) -> RecipeServiceProtocol {
        let factory = RecipeServiceFactory()
        return factory.makeRemoteService(session: session)
    }
    
    /// Create a mock service for testing
    static func makeMockService(recipesDTO: RecipesDTO = RecipesDTO(recipes: []), error: Error? = nil) -> RecipeServiceProtocol {
        let factory = RecipeServiceFactory()
        return factory.makeMockService(recipesDTO: recipesDTO, error: error)
    }
}

/// Service responsible for fetching and validating recipes
class RecipeService: RecipeServiceProtocol {
    private let dataSource: RecipeDataSource
    
    init(dataSource: RecipeDataSource) {
        self.dataSource = dataSource
    }
    
    /// Fetch recipes using Combine
    func fetchRecipes() -> AnyPublisher<[Recipe], RecipeServiceError> {
        return dataSource.fetchRecipes()
            .mapError { error -> RecipeServiceError in
                if let decodingError = error as? DecodingError {
                    return .decodingError(decodingError.localizedDescription)
                } else {
                    return .networkError(error.localizedDescription)
                }
            }
            .tryMap { recipesDTO -> [Recipe] in
                do {
                    return try recipesDTO.validate()
                } catch let error as RecipeValidationError {
                    throw RecipeServiceError.validationError(error.localizedDescription)
                } catch {
                    throw RecipeServiceError.validationError("Unknown validation error")
                }
            }
            .mapError { error -> RecipeServiceError in
                if let serviceError = error as? RecipeServiceError {
                    return serviceError
                }
                return .validationError(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    /// Fetch recipes using completion handler
    func fetchRecipes(completion: @escaping (Result<[Recipe], RecipeServiceError>) -> Void) {
        dataSource.fetchRecipes { result in
            switch result {
            case .success(let recipesDTO):
                do {
                    // Validate the recipes
                    let recipes = try recipesDTO.validate()
                    completion(.success(recipes))
                } catch let validationError as RecipeValidationError {
                    completion(.failure(.validationError(validationError.localizedDescription)))
                } catch {
                    completion(.failure(.validationError("Unknown error: \(error)")))
                }
                
            case .failure(let error):
                if let decodingError = error as? DecodingError {
                    completion(.failure(.decodingError(decodingError.localizedDescription)))
                } else {
                    completion(.failure(.networkError(error.localizedDescription)))
                }
            }
        }
    }
}

