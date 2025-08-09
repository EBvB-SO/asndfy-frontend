//
//  ExerciseMatchHelper.swift
//  Ascendify
//
//  Created by Ellis Barker on 20/04/2025.
//

import Foundation
import SwiftUI

extension String {
    func levenshteinDistance(to target: String) -> Int {
        let source = Array(self)
        let target = Array(target)
                    
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: target.count + 1),
                             count: source.count + 1)
                    
        for i in 0...source.count {
            matrix[i][0] = i
        }
        for j in 0...target.count {
            matrix[0][j] = j
        }
        for i in 1...source.count {
            for j in 1...target.count {
                if source[i-1] == target[j-1] {
                    matrix[i][j] = matrix[i-1][j-1]
                } else {
                    matrix[i][j] = Swift.min(
                        matrix[i-1][j] + 1,
                        matrix[i][j-1] + 1,
                        matrix[i-1][j-1] + 1
                    )
                }
            }
        }
                    
        return matrix[source.count][target.count]
    }
}

/// Helper class for finding exercises in the library
class ExerciseMatchHelper {
    
    // Singleton instance
    static let shared = ExerciseMatchHelper()
    
    // Enhanced map of known exercise names to their library counterparts
    private let knownExerciseMap: [String: String] = [
        // EXACT MATCHES (should work immediately)
        "fingerboard max hangs": "Fingerboard Max Hangs (Crimps)",
        "max boulder sessions": "Max Boulder Sessions",
        "boulder 4x4s": "Boulder 4x4s",
        "continuous low-intensity climbing": "Continuous Low-Intensity Climbing",
        "route 4x4s": "Route 4x4s",
        "campus board exercises": "Campus Board Exercises",
        
        // VARIATIONS AND ALIASES
        "fingerboard max hangs (crimps)": "Fingerboard Max Hangs (Crimps)",
        "fingerboard max hangs (pockets)": "Fingerboard Max Hangs (Pockets)",
        "hangboard max hangs": "Fingerboard Max Hangs (Crimps)",
        "max hangs": "Fingerboard Max Hangs (Crimps)",
        "campus board": "Campus Board Exercises",
        "campus": "Campus Board Exercises",
        "limit bouldering": "Max Boulder Sessions",
        "max bouldering": "Max Boulder Sessions",
        "4x4s": "Boulder 4x4s",
        "boulder 4x4": "Boulder 4x4s",
        "arc": "Continuous Low-Intensity Climbing",
        "continuous climbing": "Continuous Low-Intensity Climbing",
        "endurance climbing": "Continuous Low-Intensity Climbing",
        
        // SPECIFIC EXERCISES FROM YOUR LIBRARY
        "short boulder repeats": "Short Boulder Repeats",
        "weighted pull-ups": "Weighted Pull-Ups",
        "plank": "Plank",
        "front lever": "Front Lever Progressions",
        "front lever progressions": "Front Lever Progressions",
        "hanging leg raises": "Hanging Leg Raises",
        "hanging knee raises": "Hanging Knee Raises",
        "mixed intensity laps": "Mixed Intensity Laps",
        "x-on, x-off intervals": "X-On, X-Off Intervals",
        "linked laps": "Linked Laps",
        "low intensity fingerboarding": "Low Intensity Fingerboarding",
        "foot-on campus endurance": "Foot-On Campus Endurance",
        "long boulder circuits": "Long Boulder Circuits",
        "boulder triples": "Boulder Triples",
        "linked bouldering circuits": "Linked Bouldering Circuits",
        "campus laddering": "Campus Laddering",
        "fingerboard repeater blocks": "Fingerboard Repeater Blocks",
        "multiple set boulder circuits": "Multiple Set Boulder Circuits",
        "density hangs": "Density Hangs",
        "30-move circuits": "30-Move Circuits",
        "on-the-minute bouldering": "On-The-Minute Bouldering",
        "3x3 bouldering circuits": "3x3 Bouldering Circuits",
        "intensive foot-on campus": "Intensive Foot-On Campus",
        "broken circuits": "Broken Circuits",
        "max intensity redpoints": "Max Intensity Redpoints",
        "board session": "Board Session",
        "boulder pyramids": "Boulder Pyramids",
        "boulder intervals": "Boulder Intervals",
        "volume bouldering": "Volume Bouldering",
        "dead hangs": "Dead Hangs",
        "one-arm lock-offs": "One-Arm Lock-Offs",
        "campus bouldering": "Campus Bouldering",
        "explosive pull-ups": "Explosive Pull-Ups",
        "window wipers": "Window Wipers",
        "silent feet drills": "Silent Feet Drills",
        "flagging practice": "Flagging Practice",
        "high-step drills": "High-Step Drills",
        "cross-through drills": "Cross-Through Drills",
        "open-hand grip practice": "Open-Hand Grip Practice",
        "slow climbing": "Slow Climbing",
        "rest position training": "Rest Position Training",
        "dynamic movement practice": "Dynamic Movement Practice",
        "flexibility and mobility circuit": "Flexibility and Mobility Circuit",
        "dynamic hip mobility": "Dynamic Hip Mobility",
        "shoulder mobility flow": "Shoulder Mobility Flow",
        "ankle and foot mobility": "Ankle and Foot Mobility",
        
        // WARM-UP AND COOL-DOWN
        "general warm-up": "General Warm-up",
        "general warm-up (5-10 minutes)": "General Warm-up",
        "general warm-up (10-15 minutes)": "General Warm-up",
        "warm-up": "General Warm-up",
        "warmup": "General Warm-up",
        "warm up": "General Warm-up",
        "dynamic stretching": "Dynamic Stretching",
        "dynamic stretch": "Dynamic Stretching",
        "dynamic stretches": "Dynamic Stretching",
        "light stretching": "Light Stretching",
        "light stretch": "Light Stretching",
        "static stretching": "Light Stretching",
        "cool-down exercises": "Cool-down Exercises",
        "cool-down": "Cool-down Exercises",
        "cooldown": "Cool-down Exercises",
        "cool down": "Cool-down Exercises",
        "stretch": "Light Stretching",
        "stretching": "Light Stretching",
        "stretches": "Light Stretching",
        
        // SESSION COMPLETE MARKER
        "session complete": "Cool-down Exercises"
    ]
    
    /// Find a matching exercise in the library
    /// - Parameter name: The name of the exercise to find
    /// - Returns: The exercise and its category if found, nil otherwise
    func findExercise(byName name: String) -> (Exercise, ExerciseCategory)? {
        // 1. Force load library if needed
        ensureLibraryLoaded()
        
        // Clean the input name
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("🔍 ExerciseMatchHelper: Looking for exercise '\(cleanedName)'")
        
        // 2. Check the known exercise map first (case-insensitive)
        let searchKey = cleanedName.lowercased()
        if let mappedName = knownExerciseMap[searchKey] {
            print("🔍 Found mapping: '\(searchKey)' -> '\(mappedName)'")
            for category in ExerciseLibraryManager.shared.categories {
                for exercise in category.exercises {
                    if exercise.name == mappedName {
                        print("✅ Found exercise via direct mapping: \(exercise.name)")
                        return (exercise, category)
                    }
                }
            }
            print("❌ Mapping found but exercise not in library: \(mappedName)")
        }
        
        // 3. Try exact match (case insensitive)
        for category in ExerciseLibraryManager.shared.categories {
            for exercise in category.exercises {
                if exercise.name.lowercased() == cleanedName.lowercased() {
                    print("✅ Found exact match: \(exercise.name)")
                    return (exercise, category)
                }
            }
        }
        
        // 4. Try removing common prefixes/suffixes and search again
        let processedName = Self.cleanExerciseTitle(cleanedName)
        if processedName != cleanedName {
            print("🔍 Trying processed name: '\(processedName)'")
            return findExercise(byName: processedName)
        }
        
        // 5. Try substring match
        for category in ExerciseLibraryManager.shared.categories {
            for exercise in category.exercises {
                let exerciseLower = exercise.name.lowercased()
                let searchLower = cleanedName.lowercased()
                
                if exerciseLower.contains(searchLower) || searchLower.contains(exerciseLower) {
                    print("✅ Found substring match: \(exercise.name)")
                    return (exercise, category)
                }
            }
        }
        
        // 6. Try keyword-based matching with improved scoring
        let words = cleanedName.lowercased()
            .split(separator: " ")
            .map { String($0) }
            .filter { $0.count > 2 }
        
        print("🔍 Trying keyword match with words: \(words)")
        
        var bestMatch: (exercise: Exercise, category: ExerciseCategory, score: Int)?
        
        for category in ExerciseLibraryManager.shared.categories {
            for exercise in category.exercises {
                let exerciseWords = exercise.name.lowercased()
                    .split(separator: " ")
                    .map { String($0) }
                var score = 0
                
                // Count matching words with higher weight for exact matches
                for word in words {
                    if exerciseWords.contains(word) {
                        score += 3 // Exact word match
                    } else if exerciseWords.contains(where: { $0.contains(word) || word.contains($0) }) {
                        score += 1 // Partial word match
                    }
                }
                
                // Bonus for similar length
                let lengthDiff = abs(exerciseWords.count - words.count)
                if lengthDiff <= 1 {
                    score += 2
                }
                
                // Update best match if this score is higher
                if score > 2 && (bestMatch == nil || score > bestMatch!.score) {
                    bestMatch = (exercise, category, score)
                }
            }
        }
        
        if let match = bestMatch {
            print("✅ Found via keyword scoring: \(match.exercise.name) with score \(match.score)")
            return (match.exercise, match.category)
        }
        
        // 7. Try category-based fallback
        let categoryKeywords = [
            "fingerboard": "Finger Strength",
            "hang": "Finger Strength",
            "boulder": "Strength",
            "campus": "Power",
            "core": "Core",
            "stretch": "Mobility",
            "warm": "Warm Up and Cool Down",
            "cool": "Warm Up and Cool Down"
        ]
        
        for (keyword, categoryName) in categoryKeywords {
            if cleanedName.lowercased().contains(keyword) {
                if let category = ExerciseLibraryManager.shared.categories.first(where: { $0.name == categoryName }),
                   let firstExercise = category.exercises.first {
                    print("✅ Found via category fallback: \(firstExercise.name) in \(categoryName)")
                    return (firstExercise, category)
                }
            }
        }
        
        // No match found
        print("❌ No exercise match found for: \(name)")
        print("❌ Available categories: \(ExerciseLibraryManager.shared.categories.count)")
        
        // Debug: show a few available exercises
        for category in ExerciseLibraryManager.shared.categories.prefix(2) {
            print("  Category: \(category.name)")
            for exercise in category.exercises.prefix(3) {
                print("    - \(exercise.name)")
            }
        }
        
        return nil
    }
    
    /// Clean exercise title by removing common variations
    static func cleanExerciseTitle(_ title: String) -> String {
        var cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common prefixes
        let prefixes = ["do ", "perform ", "complete ", "the "]
        for prefix in prefixes {
            if cleaned.lowercased().hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count))
            }
        }
        
        // Remove common suffixes
        let suffixes = [" exercise", " exercises", " drill", " drills", " workout", " session", " training"]
        for suffix in suffixes {
            if cleaned.lowercased().hasSuffix(suffix) {
                cleaned = String(cleaned.dropLast(suffix.count))
            }
        }
        
        // Remove parenthetical content (e.g., "(5-10 minutes)")
        while let range = cleaned.range(of: #"\s*\([^)]+\)"#, options: .regularExpression) {
            cleaned.removeSubrange(range)
        }
        
        // Clean up extra whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespaces)
        
        // Remove multiple spaces
        cleaned = cleaned.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        
        return cleaned
    }
    
    /// Ensure the exercise library is loaded
    private func ensureLibraryLoaded() {
        if ExerciseLibraryManager.shared.categories.isEmpty {
            print("🔍 ExerciseMatchHelper: Library empty, loading...")
            let exerciseLib = ExerciseLib()
            ExerciseLibraryManager.shared.initializeWithLibrary(categories: exerciseLib.categories)
            print("🔍 ExerciseMatchHelper: Initialized library with \(ExerciseLibraryManager.shared.categories.count) categories")
            
            // Debug: print all exercise names for debugging
            print("🔍 Available exercises:")
            for category in ExerciseLibraryManager.shared.categories {
                print("  📁 \(category.name):")
                for exercise in category.exercises {
                    print("    - \(exercise.name)")
                }
            }
        }
    }

    func findClosestMatch(for name: String) -> (Exercise, ExerciseCategory)? {
        ensureLibraryLoaded()
        
        var bestMatch: (exercise: Exercise, category: ExerciseCategory, distance: Int)?
        let cleanName = name.lowercased()
        
        for category in ExerciseLibraryManager.shared.categories {
            for exercise in category.exercises {
                let exerciseName = exercise.name.lowercased()
                let distance = cleanName.levenshteinDistance(to: exerciseName)
                let threshold = min(cleanName.count, exerciseName.count) / 3 // Allow ~33% difference
                
                if distance <= threshold {
                    if bestMatch == nil || distance < bestMatch!.distance {
                        bestMatch = (exercise, category, distance)
                    }
                }
            }
        }
        
        if let match = bestMatch {
            print("✅ Found fuzzy match: \(match.exercise.name) (distance: \(match.distance))")
            return (match.exercise, match.category)
        }
        
        return nil
    }
}
