//
//  ExerciseLibraryManager.swift
//  Ascendify
//
//  Created by Ellis Barker on 09/03/2025.
//

import SwiftUI

// Create a manager class to connect plan exercises with library exercises
class ExerciseLibraryManager: ObservableObject {
    static let shared = ExerciseLibraryManager()
    
    // Store the categories from ExerciseLib for lookup
    // Make this internal instead of private so it can be accessed by other classes
    internal var categories: [ExerciseCategory] = []
    
    // Initialize with the exercise library data
    func initializeWithLibrary(categories: [ExerciseCategory]) {
        self.categories = categories
    }
    
    // Find a matching library exercise from a plan exercise
    func findMatchingLibraryExercise(for planExercise: PlanExercise) -> (Exercise, ExerciseCategory)? {
        // First try exact title match (case-insensitive)
        let searchTitle = planExercise.title.lowercased()
        
        // 1. Direct match by name (most precise)
        for category in categories {
            for exercise in category.exercises {
                if exercise.name.lowercased() == searchTitle {
                    return (exercise, category)
                }
            }
        }
        
        // 2. Try a contains match by name
        for category in categories {
            for exercise in category.exercises {
                let exerciseName = exercise.name.lowercased()
                if searchTitle.contains(exerciseName) || exerciseName.contains(searchTitle) {
                    return (exercise, category)
                }
            }
        }
        
        // 3. Try partial match with keywords
        if let keywords = extractKeywords(from: planExercise.title) {
            for category in categories {
                for exercise in category.exercises {
                    for keyword in keywords {
                        // Reduced minimum keyword length for better matching
                        if keyword.count >= 3 && exercise.name.lowercased().contains(keyword) {
                            return (exercise, category)
                        }
                    }
                }
            }
        }
        
        // 4. Try fuzzy match by common words
        for category in categories {
            for exercise in category.exercises {
                let exerciseName = exercise.name.lowercased()
                let exerciseWords = exerciseName.split(separator: " ").map { String($0) }
                let titleWords = searchTitle.split(separator: " ").map { String($0) }
                
                // Match if there are at least 2 common words, or 1 word if that's all there is
                let commonWords = exerciseWords.filter { titleWords.contains($0) }
                if commonWords.count >= 2 || (exerciseWords.count == 1 && titleWords.contains(exerciseWords[0])) {
                    return (exercise, category)
                }
            }
        }
        
        // 5. Check description similarity (if no name match found)
        let searchDescription = planExercise.description.lowercased()
        
        if !searchDescription.isEmpty {
            for category in categories {
                for exercise in category.exercises {
                    // Look for significant words from the exercise name in the plan exercise description
                    let exerciseNameWords = exercise.name.lowercased().split(separator: " ")
                        .map { String($0).trimmingCharacters(in: .punctuationCharacters) }
                        .filter { $0.count > 3 } // Only consider significant words
                    
                    for word in exerciseNameWords {
                        if searchDescription.contains(word) {
                            return (exercise, category)
                        }
                    }
                }
            }
        }
        
        // 6. Match by type as fallback
        let searchType = planExercise.type.lowercased()
        if let typeCategory = categories.first(where: {
            $0.name.lowercased().contains(searchType) ||
            searchType.contains($0.name.lowercased())
        }), let firstExercise = typeCategory.exercises.first {
            return (firstExercise, typeCategory)
        }
        
        // 7. Look for specific keywords in the title
        if let keywords = extractSpecificKeywords(from: searchTitle) {
            for keyword in keywords {
                for category in categories {
                    for exercise in category.exercises {
                        if exercise.name.lowercased().contains(keyword) {
                            return (exercise, category)
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    // Extract meaningful keywords from exercise title
    private func extractKeywords(from title: String) -> [String]? {
        let excludedWords = ["and", "the", "with", "for", "in", "on", "of", "to", "a", "an"]
        let words = title.lowercased().split(separator: " ")
            .map { String($0).trimmingCharacters(in: .punctuationCharacters) }
            .filter { $0.count > 3 && !excludedWords.contains($0) }
        
        return words.isEmpty ? nil : words
    }
    
    // Extract specific exercise-related keywords
    private func extractSpecificKeywords(from title: String) -> [String]? {
        let specificKeywords = [
            "fingerboard", "campus", "hang", "boulder", "climbing",
            "core", "strength", "power", "endurance", "technique",
            "limit", "max", "drill", "circuit", "repeat", "session"
        ]
        
        let matches = specificKeywords.filter { title.lowercased().contains($0) }
        return matches.isEmpty ? nil : matches
    }
    
    // Added for better name-based matching
    // Add this method to ExerciseLibraryManager.swift
    
    func findExactExercise(byName name: String) -> (Exercise, ExerciseCategory)? {
        // First, use the ExerciseMatchHelper which has all the mappings
        if let match = ExerciseMatchHelper.shared.findExercise(byName: name) {
            return match
        }
        
        // Fallback to original logic if helper doesn't find it
        let searchName = name.lowercased()
        
        for category in categories {
            for exercise in category.exercises {
                if exercise.name.lowercased() == searchName {
                    return (exercise, category)
                }
            }
        }
        
        // If no exact match is found, try the more flexible matching
        let planExercise = PlanExercise(
            type: "unknown",  // We'll let the matcher determine the type
            title: name,
            description: ""
        )
        
        return findMatchingLibraryExercise(for: planExercise)
    }
}
