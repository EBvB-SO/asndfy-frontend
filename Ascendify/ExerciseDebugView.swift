//
//  ExerciseDebugView.swift
//  Ascendify
//
//  Created by Ellis Barker on 03/08/2025.
//

import SwiftUI

struct ExerciseDebugView: View {
    @State private var testTitle = "Fingerboard Max Hangs"
    @State private var result = "No test performed"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Exercise Matching Debug")
                .font(.title)
                .bold()
            
            TextField("Enter exercise title", text: $testTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button("Test Match") {
                testExerciseMatch()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            ScrollView {
                Text(result)
                    .font(.system(size: 12, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    private func testExerciseMatch() {
        var debugOutput = "🔍 Testing exercise match for: '\(testTitle)'\n\n"
        
        // Test the library loading
        debugOutput += "📚 Library Status:\n"
        debugOutput += "Categories: \(ExerciseLibraryManager.shared.categories.count)\n"
        
        if ExerciseLibraryManager.shared.categories.isEmpty {
            debugOutput += "❌ Library is empty! Loading...\n"
            let exerciseLib = ExerciseLib()
            ExerciseLibraryManager.shared.initializeWithLibrary(categories: exerciseLib.categories)
            debugOutput += "✅ Loaded \(ExerciseLibraryManager.shared.categories.count) categories\n"
        }
        
        debugOutput += "\n📋 Available exercises (first 10):\n"
        var count = 0
        for category in ExerciseLibraryManager.shared.categories {
            for exercise in category.exercises {
                if count < 10 {
                    debugOutput += "  - \(exercise.name) (\(category.name))\n"
                    count += 1
                }
            }
        }
        
        debugOutput += "\n🔍 Testing match:\n"
        
        // Test the match
        if let (exercise, category) = ExerciseMatchHelper.shared.findExercise(byName: testTitle) {
            debugOutput += "✅ MATCH FOUND!\n"
            debugOutput += "Exercise: \(exercise.name)\n"
            debugOutput += "Category: \(category.name)\n"
            debugOutput += "Description: \(exercise.details.prefix(100))...\n"
        } else {
            debugOutput += "❌ NO MATCH FOUND\n"
            
            // Try cleaned version
            let cleaned = ExerciseMatchHelper.cleanExerciseTitle(testTitle)
            debugOutput += "Cleaned title: '\(cleaned)'\n"
            
            if let (exercise, category) = ExerciseMatchHelper.shared.findExercise(byName: cleaned) {
                debugOutput += "✅ MATCH FOUND with cleaned title!\n"
                debugOutput += "Exercise: \(exercise.name)\n"
                debugOutput += "Category: \(category.name)\n"
            } else {
                debugOutput += "❌ No match even with cleaned title\n"
                
                // Try fuzzy match
                if let (exercise, category) = ExerciseMatchHelper.shared.findClosestMatch(for: testTitle) {
                    debugOutput += "🔍 FUZZY MATCH FOUND!\n"
                    debugOutput += "Exercise: \(exercise.name)\n"
                    debugOutput += "Category: \(category.name)\n"
                } else {
                    debugOutput += "❌ No fuzzy match either\n"
                }
            }
        }
        
        result = debugOutput
    }
}

struct ExerciseDebugView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseDebugView()
    }
}
