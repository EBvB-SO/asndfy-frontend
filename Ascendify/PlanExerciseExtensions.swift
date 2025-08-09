//
//  PlanExerciseExtensions.swift
//  Ascendify
//
//  Created by Ellis Barker on 09/03/2025.
//

import SwiftUI

extension PlanExercise {
    // Get the actual library exercise if available
    private func getLibraryExercise() -> (Exercise, ExerciseCategory)? {
        return ExerciseLibraryManager.shared.findExactExercise(byName: self.title)
    }
    
    // Map exercise type to SF Symbol icon name based on library category
    var iconName: String {
        // First try to get the category from the library
        if let (_, category) = getLibraryExercise() {
            // Return icon based on category name
            switch category.name.lowercased() {
            case "strength", "strength & power":
                return "bolt.circle"
            case "power":
                return "bolt.fill"
            case "aerobic capacity":
                return "flame"
            case "anaerobic capacity":
                return "flame.fill"
            case "aerobic power":
                return "bolt"
            case "anaerobic power":
                return "bolt.circle.fill"
            case "core":
                return "figure.core.training"
            case "mobility":
                return "figure.flexibility"
            case "technique":
                return "figure.mind.and.body"
            default:
                return "figure.climbing"
            }
        }
        
        // Fallback to type-based icon if exercise not found in library
        let type = self.type.lowercased()
        
        if type.contains("fingerboard") || type.contains("hangboard") {
            return "hand.point.up.left.fill"
        } else if type.contains("campus") {
            return "figure.climbing"
        } else if type.contains("strength") || type.contains("power") {
            return "bolt.circle"
        } else if type.contains("endurance") {
            return "flame"
        } else if type.contains("core") || type.contains("abs") {
            return "figure.core.training"
        } else if type.contains("technique") || type.contains("skill") {
            return "figure.mind.and.body"
        } else if type.contains("rest") || type.contains("recovery") {
            return "bed.double.fill"
        } else if type.contains("stretch") || type.contains("mobility") {
            return "figure.flexibility"
        } else {
            return "figure.climbing"
        }
    }
    
    // Determine color based on exercise intensity and category
    var iconColor: Color {
        // First try to get the category from the library
        if let (_, category) = getLibraryExercise() {
            // For high-intensity categories - red
            if category.name.lowercased().contains("strength") ||
               category.name.lowercased().contains("power") {
                return .red
            }
            
            // For moderate-intensity categories - orange
            if category.name.lowercased().contains("anaerobic") {
                return .orange
            }
            
            // For lower-intensity categories - green
            if category.name.lowercased().contains("aerobic") {
                return .green
            }
            
            // For technical/skill categories - blue/teal
            if category.name.lowercased().contains("technique") ||
               category.name.lowercased().contains("mobility") {
                return .teal
            }
            
            // Default - blue
            return .blue
        }
        
        // Fallback to title/description intensity keywords if not in library
        let title = self.title.lowercased()
        let description = self.description.lowercased()
        
        if title.contains("max") || title.contains("campus") ||
           description.contains("high intensity") || description.contains("maximum effort") {
            return .red
        } else if title.contains("4x4") || title.contains("intervals") ||
                description.contains("medium intensity") || description.contains("moderate") {
            return .orange
        } else if title.contains("low intensity") || title.contains("continuous") ||
                description.contains("low intensity") || description.contains("easy") {
            return .green
        } else {
            return .teal
        }
    }
}
