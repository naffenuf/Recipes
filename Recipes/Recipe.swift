//
//  Recipe.swift
//  Recipes
//
//  Created by Craig Boyce on 3/8/25.
//
import Foundation

/// Domain model for a Recipe
struct Recipe: Codable, Identifiable, Equatable {
    let id: String
    let cuisine: String
    let name: String
    let largePhotoUrl: String
    let smallPhotoUrl: String
    let siteUrl: String
    let videoUrl: String
    
    // Added Equatable conformance for easier testing
    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        return lhs.id == rhs.id &&
               lhs.cuisine == rhs.cuisine &&
               lhs.name == rhs.name &&
               lhs.largePhotoUrl == rhs.largePhotoUrl &&
               lhs.smallPhotoUrl == rhs.smallPhotoUrl &&
               lhs.siteUrl == rhs.siteUrl &&
               lhs.videoUrl == rhs.videoUrl
    }
}
