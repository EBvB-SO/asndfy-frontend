//
//  SimplifiedSyncDebugView.swift
//  Ascendify
//
//  Created by Ellis Barker on 04/08/2025.
//

import SwiftUI

struct SimplifiedSyncDebugView: View {
    @ObservedObject private var trackingManager = SessionTrackingManager.shared
    @State private var selectedPlanId: String = ""
    @State private var testResults: [String] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Status Card
                    statusCard
                    
                    // Plan Selection
                    planSelectionCard
                    
                    // Quick Stats
                    if !selectedPlanId.isEmpty {
                        quickStatsCard
                    }
                    
                    // Test Buttons
                    testButtonsCard
                    
                    // Results
                    if !testResults.isEmpty {
                        resultsCard
                    }
                }
                .padding()
            }
            .navigationBarTitle("Sync Debug", displayMode: .inline)
            .navigationBarItems(trailing: Button("Clear") {
                testResults.removeAll()
            })
        }
        .onAppear {
            if let firstPlan = trackingManager.sessionTracking.keys.first {
                selectedPlanId = firstPlan
            }
        }
    }
    
    // MARK: - Status Card
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("System Status")
                .font(.headline)
            
            HStack {
                Circle()
                    .fill(trackingManager.networkStatus == .connected ? .green : .red)
                    .frame(width: 10, height: 10)
                Text("Network: \(trackingManager.networkStatus == .connected ? "Connected" : "Offline")")
                
                Spacer()
                
                if trackingManager.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Syncing...")
                        .font(.caption)
                }
            }
            
            if let lastSync = trackingManager.lastSyncTime {
                Text("Last sync: \(lastSync, formatter: timeFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Pending updates: \(trackingManager.totalPendingUpdates)")
                .font(.caption)
                .foregroundColor(trackingManager.totalPendingUpdates > 0 ? .orange : .secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Plan Selection Card
    private var planSelectionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Plan")
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
    
    // MARK: - Quick Stats Card
    private var quickStatsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Plan: \(selectedPlanId)")
                .font(.headline)
            
            let sessions = trackingManager.sessionTracking[selectedPlanId] ?? []
            let exercises = trackingManager.exerciseHistory[selectedPlanId] ?? []
            let syncStatus = trackingManager.getSyncStatus(for: selectedPlanId)
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(sessions.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Sessions")
                        .font(.caption)
                }
                
                VStack {
                    Text("\(exercises.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Exercises")
                        .font(.caption)
                }
                
                VStack {
                    Text("\(syncStatus.synced)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Synced")
                        .font(.caption)
                }
                
                VStack {
                    Text("\(syncStatus.failed)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("Failed")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Test Buttons Card
    private var testButtonsCard: some View {
        VStack(spacing: 12) {
            Text("Tests")
                .font(.headline)
            
            Button("Test Server Connection") {
                testServerConnection()
            }
            .disabled(isLoading)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            if !selectedPlanId.isEmpty {
                Button("Create Test Exercise") {
                    createTestExercise()
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
                .disabled(isLoading || trackingManager.networkStatus != .connected)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            Button("Clear All Data") {
                clearAllData()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
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
            .frame(maxHeight: 200)
            .background(Color(.systemGray5))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Formatters
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    // MARK: - Test Functions
    private func testServerConnection() {
        isLoading = true
        addResult("Testing server connection...")
        
        Task {
            let result = await trackingManager.testServerConnectivity()
            
            await MainActor.run {
                if result.success {
                    addResult("✅ Server connection successful")
                } else {
                    addResult("❌ Server connection failed: \(result.message)")
                }
                isLoading = false
            }
        }
    }
    
    private func createTestExercise() {
        guard !selectedPlanId.isEmpty else { return }
        
        addResult("Creating test exercise...")
        
        // Get first session for this plan
        let sessions = trackingManager.sessionTracking[selectedPlanId] ?? []
        guard let firstSession = sessions.first else {
            addResult("❌ No sessions found for plan")
            return
        }
        
        // Create test exercise
        let exerciseId = UUID()
        let exerciseTitle = "Test Exercise \(Int(Date().timeIntervalSince1970))"
        let exerciseKey = trackingManager.generateExerciseKey(
            planId: selectedPlanId,
            sessionId: firstSession.id,
            title: exerciseTitle
        )
        
        let tracking = trackingManager.recordExerciseCompletionWithKey(
            planId: selectedPlanId,
            sessionId: firstSession.id,
            exerciseId: exerciseId,
            exerciseTitle: exerciseTitle,
            exerciseKey: exerciseKey,
            notes: "Test notes from debug view"
        )
        
        addResult("✅ Created test exercise: \(exerciseTitle)")
        addResult("   ID: \(tracking.id)")
        addResult("   Key: \(exerciseKey)")
        
        // Check if it was saved locally
        let isCompleted = trackingManager.isExerciseCompletedByKey(
            planId: selectedPlanId,
            sessionId: firstSession.id,
            exerciseKey: exerciseKey
        )
        
        if isCompleted {
            addResult("✅ Exercise saved locally")
        } else {
            addResult("❌ Exercise not found locally")
        }
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
    
    private func clearAllData() {
        trackingManager.clearAllData()
        addResult("🗑️ All data cleared")
        selectedPlanId = ""
    }
    
    private func addResult(_ message: String) {
        let timestamp = timeFormatter.string(from: Date())
        testResults.append("[\(timestamp)] \(message)")
        
        // Keep only last 50 results
        if testResults.count > 50 {
            testResults.removeFirst()
        }
    }
}

struct SimplifiedSyncDebugView_Previews: PreviewProvider {
    static var previews: some View {
        SimplifiedSyncDebugView()
    }
}
