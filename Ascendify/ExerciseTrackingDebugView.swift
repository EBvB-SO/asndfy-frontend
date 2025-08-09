//
//  ExerciseTrackingDebugView.swift
//  Ascendify
//

import SwiftUI

struct ExerciseTrackingDebugView: View {
    @ObservedObject private var trackingManager = SessionTrackingManager.shared
    @State private var selectedPlanId: String = ""
    @State private var testResults: [String] = []
    @State private var isLoading = false
    @State private var showCreateTest = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerCard
                    planSelectorCard
                    
                    if !selectedPlanId.isEmpty {
                        exerciseStatsCard
                        testButtonsCard
                        historyPreviewCard
                    }
                    
                    if !testResults.isEmpty {
                        resultsCard
                    }
                }
                .padding()
            }
            .navigationTitle("Exercise Debug")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Clear Results") {
                    testResults.removeAll()
                },
                trailing: Button("Refresh") {
                    trackingManager.objectWillChange.send()
                }
            )
        }
        .onAppear {
            if let firstPlan = trackingManager.sessionTracking.keys.first {
                selectedPlanId = firstPlan
            }
        }
        .sheet(isPresented: $showCreateTest) {
            CreateTestExerciseView(planId: selectedPlanId) { result in
                addResult(result)
            }
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercise Tracking Debug")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Network")
                    HStack {
                        Circle()
                            .fill(trackingManager.networkStatus == .connected ? .green : .red)
                            .frame(width: 8, height: 8)
                        Text(trackingManager.networkStatus == .connected ? "Connected" : "Offline")
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Pending Updates")
                    Text("\(trackingManager.totalPendingUpdates)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(trackingManager.totalPendingUpdates > 0 ? .orange : .green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Plan Selector
    private var planSelectorCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Plan to Debug")
                .font(.headline)
            
            if trackingManager.sessionTracking.isEmpty {
                Text("No plans available")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                Picker("Plan", selection: $selectedPlanId) {
                    ForEach(Array(trackingManager.sessionTracking.keys).sorted(), id: \.self) { planId in
                        Text(planId).tag(planId)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Exercise Stats
    private var exerciseStatsCard: some View {
        let exercises = trackingManager.exerciseHistory[selectedPlanId] ?? []
        let sessions = trackingManager.sessionTracking[selectedPlanId] ?? []
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Plan: \(selectedPlanId)")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatBox(title: "Sessions", value: "\(sessions.count)")
                StatBox(title: "Exercises", value: "\(exercises.count)")
                StatBox(title: "Synced", value: "\(exercises.filter { $0.isSynced }.count)")
                StatBox(title: "Failed", value: "\(exercises.filter { $0.syncError != nil }.count)")
            }
            
            // Recent exercises preview
            if !exercises.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Exercises")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(exercises.sorted { $0.date > $1.date }.prefix(3), id: \.id) { exercise in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(extractExerciseTitle(from: exercise.notes))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text(exercise.date, style: .date)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if exercise.isSynced {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            } else if exercise.syncError != nil {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Test Buttons
    private var testButtonsCard: some View {
        VStack(spacing: 12) {
            Text("Debug Actions")
                .font(.headline)
            
            Button("Create Test Exercise") {
                showCreateTest = true
            }
            .disabled(isLoading)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Test History Search") {
                testHistorySearch()
            }
            .disabled(isLoading)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Force Sync All") {
                forceSyncAll()
            }
            .disabled(isLoading)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - History Preview
    private var historyPreviewCard: some View {
        let exercises = trackingManager.exerciseHistory[selectedPlanId] ?? []
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Exercise History")
                .font(.headline)
            
            if exercises.isEmpty {
                Text("No exercise history found")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(exercises.sorted { $0.date > $1.date }, id: \.id) { exercise in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(extractExerciseTitle(from: exercise.notes))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text(exercise.date, style: .date)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(cleanNotesForDisplay(exercise.notes))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                
                                HStack {
                                    Text("ID: \(exercise.id.uuidString.prefix(8))...")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                    
                                    if exercise.isSynced {
                                        Text("✅ Synced")
                                            .font(.caption2)
                                            .foregroundColor(.green)
                                    } else if exercise.syncError != nil {
                                        Text("❌ Failed")
                                            .font(.caption2)
                                            .foregroundColor(.red)
                                    } else {
                                        Text("⏳ Pending")
                                            .font(.caption2)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color(.systemGray5))
                            .cornerRadius(6)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Results Card
    private var resultsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Test Results")
                .font(.headline)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(testResults.enumerated()), id: \.offset) { index, result in
                        Text("\(index + 1). \(result)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                }
                .padding(8)
            }
            .frame(maxHeight: 150)
            .background(Color(.systemGray5))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Views
    private struct StatBox: View {
        let title: String
        let value: String
        
        var body: some View {
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Test Functions
    private func testHistorySearch() {
        let exercises = trackingManager.exerciseHistory[selectedPlanId] ?? []
        addResult("Testing history search...")
        
        if exercises.isEmpty {
            addResult("❌ No exercises to search")
            return
        }
        
        // Test searching for each exercise
        let uniqueTitles = Set(exercises.map { extractExerciseTitle(from: $0.notes) })
        
        for title in uniqueTitles {
            let found = trackingManager.getHistoryForExerciseTitle(exerciseTitle: title, planId: selectedPlanId)
            addResult("🔍 '\(title)': Found \(found.count) matches")
        }
        
        addResult("✅ History search test complete")
    }
    
    private func forceSyncAll() {
        isLoading = true
        addResult("Starting force sync...")
        
        Task {
            await trackingManager.forceCompleteSync()
            
            await MainActor.run {
                addResult("✅ Force sync completed")
                isLoading = false
            }
        }
    }
    
    private func addResult(_ message: String) {
        let timestamp = DateFormatter().string(from: Date())
        testResults.append("[\(timestamp)] \(message)")
        
        if testResults.count > 20 {
            testResults.removeFirst()
        }
    }
    
    // MARK: - Helper Functions
    private func extractExerciseTitle(from notes: String) -> String {
        // Extract title from [EXERCISE:title] format
        if let range = notes.range(of: #"\[EXERCISE:([^\]]+)\]"#, options: .regularExpression) {
            let match = String(notes[range])
            return match
                .replacingOccurrences(of: "[EXERCISE:", with: "")
                .replacingOccurrences(of: "]", with: "")
        }
        
        // Fallback extraction
        let cleaned = notes
            .replacingOccurrences(of: "[KEY:", with: "")
            .components(separatedBy: "]")
            .dropFirst()
            .joined(separator: "]")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleaned.hasSuffix(" completed") || cleaned.hasSuffix(" Completed") {
            return String(cleaned.dropLast(10)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return cleaned.isEmpty ? "Unknown Exercise" : cleaned
    }
    
    private func cleanNotesForDisplay(_ notes: String) -> String {
        return trackingManager.cleanNotesForDisplay(notes)
    }
}

// MARK: - Create Test Exercise View
struct CreateTestExerciseView: View {
    let planId: String
    let onResult: (String) -> Void
    
    @State private var exerciseTitle = "Board Session"
    @State private var exerciseNotes = "Great session - felt really strong"
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Create Test Exercise")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Plan: \(planId)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercise Title")
                        .font(.headline)
                    
                    TextField("Enter exercise name", text: $exerciseTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                    
                    TextEditor(text: $exerciseNotes)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                Button("Create Test Exercise") {
                    createTestExercise()
                }
                .disabled(exerciseTitle.isEmpty)
                .frame(maxWidth: .infinity)
                .padding()
                .background(exerciseTitle.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Test Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    dismiss()
                }
            )
        }
    }
    
    private func createTestExercise() {
        // Get or create a test session
        let sessions = SessionTrackingManager.shared.sessionTracking[planId] ?? []
        let sessionId: UUID
        
        if let firstSession = sessions.first {
            sessionId = firstSession.id
        } else {
            // Use a pre-determined session ID that the manager will create automatically
            sessionId = UUID()
            onResult("ℹ️ No existing sessions found - using new session ID: \(sessionId)")
        }
        
        let exerciseId = UUID()
        let exerciseKey = SessionTrackingManager.shared.generateExerciseKey(
            planId: planId,
            sessionId: sessionId,
            title: exerciseTitle
        )
        
        // This will automatically create the session if it doesn't exist
        let tracking = SessionTrackingManager.shared.recordExerciseCompletionWithKey(
            planId: planId,
            sessionId: sessionId,
            exerciseId: exerciseId,
            exerciseTitle: exerciseTitle,
            exerciseKey: exerciseKey,
            notes: exerciseNotes
        )
        
        onResult("✅ Created: '\(exerciseTitle)' with ID: \(tracking.id)")
        onResult("📝 Session ID: \(sessionId)")
        onResult("🔑 Exercise Key: \(exerciseKey)")
        dismiss()
    }
}
