//
//  RecipeGridView.swift
//  Recipes
//
//  Created by Craig Boyce on 3/17/25.
//


import SwiftUI

struct RecipeGridView: View {
    let recipes: [Recipe]
    let isIpad: Bool
    
    private var gridColumns: [GridItem] {
        let columns = isIpad ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: columns)
    }
    
    var body: some View {
        ScrollView {
            HStack {
                Spacer()
                Text("\(recipes.count) Recipes")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(recipes) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                        RecipeGridItem(recipe: recipe)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
}