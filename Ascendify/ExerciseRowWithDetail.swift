//
//  ExerciseRowWithDetail.swift
//  Ascendify
//
//  Created by Ellis Barker on 20/04/2025.
//

import SwiftUI

/// A single row showing an exercise title, a tappable circle/checkmark for completion,
/// and an info-button to pull up the full ExerciseDetailView.
struct ExerciseRowWithDetail: View {
    let title: String
    let sessionId: UUID
    let planId: String
    let isDone: Bool
    let action: () -> Void

    @ObservedObject private var trackingManager = SessionTrackingManager.shared
    @State private var showExerciseDetail = false
    @State private var exerciseToShow: Exercise? = nil
    @State private var categoryToShow: ExerciseCategory? = nil
    @State private var matchAttempted = false
    @State private var matchResult = "Not attempted"
    
    // Check completion by title instead of generating new keys
    private var isReallyDone: Bool {
        return trackingManager.isExerciseCompletedByTitle(
            planId: planId,
            sessionId: sessionId,
            exerciseTitle: title
        )
    }

    var body: some View {
        HStack {
            // Completion toggle (circle ↔ checkmark)
            Button(action: action) {
                HStack {
                    // FIXED: Use isReallyDone instead of isDone
                    Image(systemName: isReallyDone ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isReallyDone ? Color.ascendGreen : .gray)
                        .frame(width: 30)
                        .contentShape(Rectangle())
                        .animation(.easeInOut(duration: 0.2), value: isReallyDone) // Add animation

                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)

                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Info button to show detail sheet
            Button {
                matchAttempted = true
                matchResult = "Looking up \"\(title)\"…"
                findExerciseAndShowDetail()
            } label: {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(item: $exerciseToShow) { exercise in
            NavigationView {
                ExerciseDetailView(exercise: exercise)
                    .navigationBarTitle(categoryToShow?.name ?? "Exercise", displayMode: .inline)
                    .navigationBarItems(trailing: Button("Close") {
                        exerciseToShow = nil
                    })
            }
        }
    }

    /// Attempts to find a matching library Exercise, then shows the sheet.
    private func findExerciseAndShowDetail() {
        DispatchQueue.global(qos: .userInitiated).async {
            var found: (Exercise, ExerciseCategory)? = nil

            print("🔍 ExerciseRowWithDetail: Looking for exercise '\(title)'")

            // 1) Try ExerciseMatchHelper first - it has the most comprehensive mapping
            found = ExerciseMatchHelper.shared.findExercise(byName: title)
            
            if found == nil {
                // 2) Try with cleaned title
                let cleanedTitle = ExerciseMatchHelper.cleanExerciseTitle(title)
                print("🔍 Trying cleaned title: '\(cleanedTitle)'")
                found = ExerciseMatchHelper.shared.findExercise(byName: cleanedTitle)
            }

            if found == nil {
                // 3) Try fuzzy matching with closest match
                found = ExerciseMatchHelper.shared.findClosestMatch(for: title)
                if found != nil {
                    print("🔍 Found via fuzzy matching")
                }
            }

            if found == nil {
                // 4) Try library manager's matching function as fallback
                let planEx = PlanExercise(
                    type: inferExerciseType(title),
                    title: title,
                    description: ""
                )
                found = ExerciseLibraryManager.shared.findMatchingLibraryExercise(for: planEx)
                if found != nil {
                    print("🔍 Found via library manager")
                }
            }

            DispatchQueue.main.async {
                if let match = found {
                    print("✅ SHOWING EXERCISE DETAIL: \(match.0.name)")
                    self.categoryToShow = match.1
                    self.exerciseToShow = match.0  // This will trigger the sheet
                    self.matchResult = "✅ Found: \(match.0.name) in \(match.1.name)"
                } else {
                    print("❌ No match found - would need fallback")
                    self.exerciseToShow = nil
                    self.categoryToShow = nil
                    self.matchResult = "❌ No match found for '\(title)'"
                    // For now, if no match, don't show anything
                    // You could add a separate fallback sheet here if needed
                }
            }
        }
    }

    /// Infers a category type from the title string
    private func inferExerciseType(_ text: String) -> String {
        let l = text.lowercased()
        if l.contains("fingerboard") || l.contains("hang")      { return "fingerboard" }
        if l.contains("boulder")                                 { return "bouldering" }
        if l.contains("core") || l.contains("plank")             { return "core" }
        if l.contains("strength")                                { return "strength" }
        if l.contains("power")                                   { return "power" }
        if l.contains("endurance")                               { return "endurance" }
        if l.contains("technique")                              { return "technique" }
        if l.contains("mobility") || l.contains("stretching")   { return "mobility" }
        if l.contains("warm")                                    { return "warm-up" }
        if l.contains("cool")                                    { return "cool-down" }
        return "climbing"
    }
}
