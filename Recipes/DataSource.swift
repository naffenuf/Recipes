//
//  DataSource.swift
//  Recipes
//
//  Created by Craig Boyce on 3/16/25.
//

import Foundation
import Combine

/// Protocol defining a data source for recipes
protocol RecipeDataSource {
    /// Fetch recipes using Combine
    func fetchRecipes() -> AnyPublisher<RecipesDTO, Error>
    
    /// Fetch recipes using completion handler
    func fetchRecipes(completion: @escaping (Result<RecipesDTO, Error>) -> Void)
}

/// Remote data source that fetches recipes from a network endpoint
class RemoteRecipeDataSource: RecipeDataSource {
    private let session: URLSession
    private let endpoint: URL
    
    init(session: URLSession = .shared, endpoint: URL) {
        self.session = session
        self.endpoint = endpoint
    }
    
    func fetchRecipes() -> AnyPublisher<RecipesDTO, Error> {
        return session.dataTaskPublisher(for: endpoint)
            .map(\.data)
            .decode(type: RecipesDTO.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func fetchRecipes(completion: @escaping (Result<RecipesDTO, Error>) -> Void) {
        let task = session.dataTask(with: endpoint) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "RecipeDataSource", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let recipesDTO = try JSONDecoder().decode(RecipesDTO.self, from: data)
                completion(.success(recipesDTO))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}

/// Local data source that loads recipes from a local JSON file
class LocalRecipeDataSource: RecipeDataSource {
    private let bundle: Bundle
    private let filename: String
    
    init(bundle: Bundle = .main, filename: String = "recipes") {
        self.bundle = bundle
        self.filename = filename
    }
    
    func fetchRecipes() -> AnyPublisher<RecipesDTO, Error> {
        return Future<RecipesDTO, Error> { promise in
            self.fetchRecipes { result in
                switch result {
                case .success(let recipesDTO):
                    promise(.success(recipesDTO))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func fetchRecipes(completion: @escaping (Result<RecipesDTO, Error>) -> Void) {
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            completion(.failure(NSError(domain: "RecipeDataSource", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find \(filename).json in bundle"])))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let recipesDTO = try JSONDecoder().decode(RecipesDTO.self, from: data)
            completion(.success(recipesDTO))
        } catch {
            completion(.failure(error))
        }
    }
}

/// Mock data source for testing
class MockRecipeDataSource: RecipeDataSource {
    private let recipesDTO: RecipesDTO
    private let error: Error?
    
    init(recipesDTO: RecipesDTO = RecipesDTO(recipes: []), error: Error? = nil) {
        self.recipesDTO = recipesDTO
        self.error = error
    }
    
    func fetchRecipes() -> AnyPublisher<RecipesDTO, Error> {
        if let error = error {
            return Fail(error: error).eraseToAnyPublisher()
        }
        return Just(recipesDTO)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchRecipes(completion: @escaping (Result<RecipesDTO, Error>) -> Void) {
        if let error = error {
            completion(.failure(error))
        } else {
            completion(.success(recipesDTO))
        }
    }
}
