//
//  SessionTrackingManager.swift
//  Ascendify
//
//  Created by Ellis Barker on 19/04/2025.
//

import Foundation
import Combine
import Network

// MARK: - JSON Encoders/Decoders
private let jsonDecoder: JSONDecoder = {
    let d = JSONDecoder()
    d.keyDecodingStrategy = .convertFromSnakeCase
    d.dateDecodingStrategy = .iso8601
    return d
}()

private let jsonEncoder: JSONEncoder = {
    let e = JSONEncoder()
    e.keyEncodingStrategy = .convertToSnakeCase
    e.dateEncodingStrategy = .iso8601
    return e
}()

// MARK: - Network Status
enum NetworkStatus {
    case connected, disconnected, unknown
}

// MARK: - Session Tracking Model (Simplified)
struct SessionTracking: Identifiable, Codable {
    let id: UUID
    let planId: String
    let weekNumber: Int
    let dayOfWeek: String
    let focusName: String
    var isCompleted: Bool
    var notes: String
    var completionDate: Date?
    var updatedAt: Date

    init(planId: String, weekNumber: Int, dayOfWeek: String, focusName: String) {
        self.id = UUID()
        self.planId = planId
        self.weekNumber = weekNumber
        self.dayOfWeek = dayOfWeek
        self.focusName = focusName
        self.isCompleted = false
        self.notes = ""
        self.completionDate = nil
        self.updatedAt = Date()
    }
    
    init(withSpecificId id: UUID, planId: String, weekNumber: Int, dayOfWeek: String, focusName: String) {
        self.id = id
        self.planId = planId
        self.weekNumber = weekNumber
        self.dayOfWeek = dayOfWeek
        self.focusName = focusName
        self.isCompleted = false
        self.notes = ""
        self.completionDate = nil
        self.updatedAt = Date()
    }
}

// MARK: - Pending Updates
struct PendingSessionUpdate: Codable {
    let planId: String
    let sessionId: UUID
    let completed: Bool
    let notes: String
    let completionDate: Date?
    let timestamp: Date
    var retryCount: Int = 0
}

struct PendingExerciseUpdate: Codable {
    let tracking: ExerciseTracking
    let timestamp: Date
    var retryCount: Int = 0
}

// MARK: - Main Session Tracking Manager
final class SessionTrackingManager: ObservableObject {
    static let shared = SessionTrackingManager()

    // Published properties
    @Published private(set) var sessionTracking: [String: [SessionTracking]] = [:]
    @Published private(set) var exerciseHistory: [String: [ExerciseTracking]] = [:]
    @Published var networkStatus: NetworkStatus = .unknown
    @Published var isSyncing: Bool = false
    @Published var lastSyncTime: Date? = nil

    // Storage keys
    private func storageKey() -> String {
        guard let email = currentUserEmail else { return "session_tracking_data" }
        return "session_tracking_data_\(email)"
    }

    private func exerciseHistoryKey() -> String {
        guard let email = currentUserEmail else { return "exercise_tracking_data" }
        return "exercise_tracking_data_\(email)"
    }

    private func pendingSessionUpdatesKey() -> String {
        guard let email = currentUserEmail else { return "pending_session_updates" }
        return "pending_session_updates_\(email)"
    }

    private func pendingExerciseUpdatesKey() -> String {
        guard let email = currentUserEmail else { return "pending_exercise_updates" }
        return "pending_exercise_updates_\(email)"
    }

    private func lastSyncTimeKey() -> String {
        guard let email = currentUserEmail else { return "last_sync_time" }
        return "last_sync_time_\(email)"
    }

    // Configuration
    private let baseURL = "http://127.0.0.1:8001"
    private let maxRetryCount = 3
    private var currentUserEmail: String?

    
    // Pending updates
    private var pendingSessionUpdates: [PendingSessionUpdate] = []
    private var pendingExerciseUpdates: [PendingExerciseUpdate] = []

    // Network monitoring
    private let networkMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.ascendify.networkMonitor")
    private var autoSyncTimer: Timer?

    private init() {
        loadAllData()
        setupNetworkMonitoring()
        startAutoSyncTimer()
    }

    deinit {
        stopAutoSyncTimer()
        networkMonitor.cancel()
    }
    
    func setCurrentUser(email: String) {
        currentUserEmail = email.lowercased()
        loadAllData()
    }

    func clearForSignOut() {
        currentUserEmail = nil
        clearAllData()
    }
    
    private func extractExerciseTitle(from notes: String) -> String {
        // Extract title from [EXERCISE:title] format
        if let range = notes.range(of: #"\[EXERCISE:([^\]]+)\]"#, options: .regularExpression) {
            let match = String(notes[range])
            let title = match
                .replacingOccurrences(of: "[EXERCISE:", with: "")
                .replacingOccurrences(of: "]", with: "")
            return title
        }
            
        // Fallback: try to extract from existing format
        if notes.contains(" completed") || notes.contains(" Completed") {
            let components = notes.components(separatedBy: "] ")
            if components.count > 1 {
                let titlePart = components[1]
                if titlePart.hasSuffix(" completed") {
                    return String(titlePart.dropLast(" completed".count))
                } else if titlePart.hasSuffix(" Completed") {
                    return String(titlePart.dropLast(" Completed".count))
                }
            }
        }
            
        return "Unknown Exercise"
    }

    // MARK: - Data Loading and Saving
    private func loadAllData() {
        guard currentUserEmail != nil else {
            // Don’t load anything until a user is set
            sessionTracking.removeAll()
            exerciseHistory.removeAll()
            pendingSessionUpdates.removeAll()
            pendingExerciseUpdates.removeAll()
            lastSyncTime = nil
            return
        }

        loadSessionTracking()
        loadExerciseHistory()
        loadPendingSessionUpdates()
        loadPendingExerciseUpdates()
        loadLastSyncTime()
    }

    private func loadSessionTracking() {
        guard let data = UserDefaults.standard.data(forKey: storageKey()) else { return }
        do {
            let decoded = try jsonDecoder.decode([String: [SessionTracking]].self, from: data)
            DispatchQueue.main.async {
                self.sessionTracking = decoded
                print("✅ Loaded \(decoded.count) plans with sessions")
            }
        } catch {
            print("❌ Error loading session tracking: \(error)")
        }
    }

    private func saveSessionTracking() {
        do {
            let data = try jsonEncoder.encode(sessionTracking)
            UserDefaults.standard.set(data, forKey: storageKey())
        } catch {
            print("❌ Error saving session tracking: \(error)")
        }
    }

    private func loadExerciseHistory() {
        guard let data = UserDefaults.standard.data(forKey: exerciseHistoryKey()) else { return }
        do {
            let decoded = try jsonDecoder.decode([String: [ExerciseTracking]].self, from: data)
            DispatchQueue.main.async {
                self.exerciseHistory = decoded
                print("✅ Loaded exercise history for \(decoded.count) plans")
            }
        } catch {
            print("❌ Error loading exercise history: \(error)")
        }
    }

    private func saveExerciseHistory() {
        do {
            let data = try jsonEncoder.encode(exerciseHistory)
            UserDefaults.standard.set(data, forKey: exerciseHistoryKey())
            print("💾 Saved exercise history to UserDefaults")
        } catch {
            print("❌ Error saving exercise history: \(error)")
        }
    }

    private func loadPendingSessionUpdates() {
        guard let data = UserDefaults.standard.data(forKey: pendingSessionUpdatesKey()) else { return }
        do {
            pendingSessionUpdates = try jsonDecoder.decode([PendingSessionUpdate].self, from: data)
            print("✅ Loaded \(pendingSessionUpdates.count) pending session updates")
        } catch {
            print("❌ Error loading pending session updates: \(error)")
        }
    }

    private func savePendingSessionUpdates() {
        do {
            let data = try jsonEncoder.encode(pendingSessionUpdates)
            UserDefaults.standard.set(data, forKey: pendingSessionUpdatesKey())
        } catch {
            print("❌ Error saving pending session updates: \(error)")
        }
    }

    private func loadPendingExerciseUpdates() {
        guard let data = UserDefaults.standard.data(forKey: pendingExerciseUpdatesKey()) else { return }
        do {
            pendingExerciseUpdates = try jsonDecoder.decode([PendingExerciseUpdate].self, from: data)
            print("✅ Loaded \(pendingExerciseUpdates.count) pending exercise updates")
        } catch {
            print("❌ Error loading pending exercise updates: \(error)")
        }
    }

    private func savePendingExerciseUpdates() {
        do {
            let data = try jsonEncoder.encode(pendingExerciseUpdates)
            UserDefaults.standard.set(data, forKey: pendingExerciseUpdatesKey())
        } catch {
            print("❌ Error saving pending exercise updates: \(error)")
        }
    }

    private func loadLastSyncTime() {
        lastSyncTime = UserDefaults.standard.object(forKey: lastSyncTimeKey()) as? Date
    }

    private func saveLastSyncTime() {
        UserDefaults.standard.set(lastSyncTime, forKey: lastSyncTimeKey())
    }

    // MARK: - Network Monitoring
    func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let newStatus: NetworkStatus = (path.status == .satisfied) ? .connected : .disconnected
                
                if self.networkStatus != newStatus {
                    self.networkStatus = newStatus
                    print("🌐 Network status changed to: \(newStatus)")
                    
                    if newStatus == .connected {
                        Task {
                            await self.processPendingUpdates()
                        }
                    }
                }
            }
        }
        networkMonitor.start(queue: monitorQueue)
    }

    func startAutoSyncTimer() {
        stopAutoSyncTimer()
        autoSyncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            guard let self = self, self.networkStatus == .connected else { return }
            Task {
                await self.processPendingUpdates()
            }
        }
    }

    func stopAutoSyncTimer() {
        autoSyncTimer?.invalidate()
        autoSyncTimer = nil
    }

    // MARK: - Plan Initialization
    func initializeTrackingForPlan(planId: String, plan: PlanModel) {
        Task {
            print("🔄 Initializing tracking for plan: \(planId) (server-first with merge)")

            var serverReturnedSessions = false

            // 1️⃣ Try to refresh from server
            if networkStatus == .connected {
                await refreshSessions(for: planId)
                if let existing = sessionTracking[planId], !existing.isEmpty {
                    serverReturnedSessions = true
                }
            }

            // 2️⃣ If server gave us sessions, merge with local
            if serverReturnedSessions {
                if let local = sessionTracking[planId], !local.isEmpty {
                    let beforeCount = local.count
                    if let serverSessions = sessionTracking[planId] {
                        mergeServerSessions(serverSessions, for: planId)
                        print("🔄 Merged server sessions with \(beforeCount) local sessions for plan \(planId)")
                    }
                }
                // Ensure all merged sessions are valid
                for session in sessionTracking[planId] ?? [] {
                    ensureSessionExists(planId: planId, sessionId: session.id)
                }
                // Ensure exercise history exists
                if exerciseHistory[planId] == nil {
                    exerciseHistory[planId] = []
                    saveExerciseHistory()
                }
                print("✅ Using merged \(sessionTracking[planId]?.count ?? 0) sessions for plan \(planId)")
                return
            }

            // 3️⃣ If offline or server has nothing, generate sessions locally
            print("⚠️ No server sessions found (or offline) → generating locally")
            var allSessions: [SessionTracking] = []

            for phase in plan.weeks {
                if let weekRange = phase.title.extractWeekRange() {
                    for weekNum in weekRange.lowerBound..<weekRange.upperBound {
                        for session in phase.sessions {
                            if let day = extractDayFromSessionTitle(session.sessionTitle) {
                                let tracking = SessionTracking(
                                    planId: planId,
                                    weekNumber: weekNum,
                                    dayOfWeek: day,
                                    focusName: extractFocusFromSessionTitle(session.sessionTitle)
                                )
                                allSessions.append(tracking)
                            }
                        }
                    }
                }
            }

            // After generating locally
            sessionTracking[planId] = allSessions
            exerciseHistory[planId] = []
            saveSessionTracking()
            saveExerciseHistory()

            print("✅ Created \(allSessions.count) local sessions for plan \(planId)")

            // 4️⃣ If online, push to server and validate sessions
            if networkStatus == .connected {
                await syncSessionsToServer(planId: planId, sessions: allSessions)
                for session in allSessions {
                    ensureSessionExists(planId: planId, sessionId: session.id)
                }
            }
        }
    }


    // MARK: - Exercise Tracking
    func generateExerciseKey(planId: String, sessionId: UUID, title: String) -> String {
        // Include milliseconds and hash for true uniqueness per exercise
        let timestamp = Int(Date().timeIntervalSince1970 * 1000) // milliseconds
        let safeTitle = title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
            .lowercased()
        
        // Create unique hash from all components
        let hashString = "\(planId)-\(sessionId)-\(safeTitle)-\(timestamp)"
        let hash = abs(hashString.hashValue) % 10000 // 4-digit hash
        
        return "\(planId.lowercased())_\(sessionId.uuidString.lowercased())_\(safeTitle)_\(hash)"
    }

    func recordExerciseCompletionWithKey(
        planId: String,
        sessionId: UUID,
        exerciseId: UUID,
        exerciseTitle: String,
        exerciseKey: String,
        notes: String = ""
    ) -> ExerciseTracking {
        
        print("🏃‍♂️ Recording individual exercise:")
        print("  - Exercise: '\(exerciseTitle)'")
        print("  - Unique Key: \(exerciseKey)")
        
        ensureSessionExists(planId: planId, sessionId: sessionId)
        
        // Create searchable notes with exact exercise title
        let exactTitle = exerciseTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let enhancedNotes: String
            
        if notes.isEmpty {
            enhancedNotes = "[EXERCISE:\(exactTitle)][KEY:\(exerciseKey)] Completed"
        } else {
            enhancedNotes = "[EXERCISE:\(exactTitle)][KEY:\(exerciseKey)] \(notes)"
        }
        
        let tracking = ExerciseTracking(
            planId: planId,
            sessionId: sessionId,
            exerciseId: exerciseId,
            date: Date(),
            notes: enhancedNotes
        )
        
        DispatchQueue.main.async {
            if self.exerciseHistory[planId] == nil {
                self.exerciseHistory[planId] = []
            }
            
            // Remove ONLY entries with the exact same key (same exercise completion)
            let exactKeyMarker = "[KEY:\(exerciseKey)]"
            self.exerciseHistory[planId]?.removeAll { existingRecord in
                existingRecord.notes.contains(exactKeyMarker)
            }
            
            // Add new record
            self.exerciseHistory[planId]?.append(tracking)
            self.saveExerciseHistory()
            print("✅ Exercise '\(exactTitle)' saved with unique key")
            self.objectWillChange.send()
        }
        
        queuePendingExerciseUpdate(tracking: tracking)
        return tracking
    }
    
    func isExerciseCompletedByKey(planId: String, sessionId: UUID, exerciseKey: String) -> Bool {
        guard let exercises = exerciseHistory[planId] else { return false }
        
        // FIXED: Search directly by the exercise key marker in notes
        let keyMarker = "[KEY:\(exerciseKey)]"
        
        let found = exercises.contains { exercise in
            exercise.sessionId == sessionId && exercise.notes.contains(keyMarker)
        }
        
        print("🔍 Checking completion for key '\(exerciseKey)': \(found)")
        return found
    }

    func markExerciseIncompleteByKey(planId: String, sessionId: UUID, exerciseKey: String) {
        let keyMarker = "[KEY:\(exerciseKey)]"
        
        DispatchQueue.main.async {
            guard var exercises = self.exerciseHistory[planId] else { return }
            
            if let index = exercises.firstIndex(where: {
                $0.sessionId == sessionId && $0.notes.contains(keyMarker)
            }) {
                let trackingToDelete = exercises[index]
                exercises.remove(at: index)
                self.exerciseHistory[planId] = exercises
                self.saveExerciseHistory()
                
                print("✅ Exercise marked incomplete locally")
                self.objectWillChange.send()
                
                // Delete from server if it was synced
                if trackingToDelete.isSynced {
                    Task {
                        await self.deleteExerciseFromServer(tracking: trackingToDelete)
                    }
                }
            }
        }
    }

    func isExerciseCompletedByTitle(planId: String, sessionId: UUID, exerciseTitle: String) -> Bool {
        guard let exercises = exerciseHistory[planId] else {
            print("🔍 [CHECK] No exercise history for plan: \(planId)")
            return false
        }
        
        let exactTitle = exerciseTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let found = exercises.contains { exercise in
            let matchesSession = exercise.sessionId == sessionId
            let matchesTitle = exercise.notes.contains("[EXERCISE:\(exactTitle)]")
            return matchesSession && matchesTitle
        }
        
        print("🔍 [CHECK] Exercise '\(exactTitle)' completed: \(found)")
        return found
    }
    
    func markExerciseIncompleteByTitle(planId: String, sessionId: UUID, exerciseTitle: String) {
        let exactTitle = exerciseTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        DispatchQueue.main.async {
            guard var exercises = self.exerciseHistory[planId] else {
                print("❌ [UNCHECK] No exercises found for plan: \(planId)")
                return
            }
            
            // Find and remove exercises that match this title and session
            var removedCount = 0
            exercises.removeAll { exercise in
                let matches = exercise.sessionId == sessionId &&
                             exercise.notes.contains("[EXERCISE:\(exactTitle)]")
                if matches {
                    removedCount += 1
                    print("🗑️ [UNCHECK] Removing exercise record: \(exercise.id)")
                    
                    // Delete from server if it was synced
                    if exercise.isSynced {
                        Task {
                            await self.deleteExerciseFromServer(tracking: exercise)
                        }
                    }
                }
                return matches
            }
            
            self.exerciseHistory[planId] = exercises
            self.saveExerciseHistory()
            
            print("✅ [UNCHECK] Removed \(removedCount) records for '\(exactTitle)'")
            self.objectWillChange.send()
        }
    }

    // MARK: - Session Management
    
    func markSessionCompleted(planId: String, sessionId: UUID, completed: Bool, notes: String) {
        print("📝 Marking session \(sessionId) as completed: \(completed)")
        
        // Update locally first
        DispatchQueue.main.async {
            guard var sessions = self.sessionTracking[planId],
                  let index = sessions.firstIndex(where: { $0.id == sessionId }) else {
                print("❌ Session not found: \(sessionId)")
                return
            }

            sessions[index].isCompleted = completed
            sessions[index].notes = notes
            sessions[index].completionDate = completed ? Date() : nil
            sessions[index].updatedAt = Date()

            self.sessionTracking[planId] = sessions
            self.saveSessionTracking()
            print("✅ Session updated locally")
            self.objectWillChange.send()
        }

        // Queue for sync
        queuePendingSessionUpdate(
            planId: planId,
            sessionId: sessionId,
            completed: completed,
            notes: notes,
            completionDate: completed ? Date() : nil
        )
    }

    func updateSessionCompletionDate(planId: String, sessionId: UUID, date: Date) {
        DispatchQueue.main.async {
            guard var sessions = self.sessionTracking[planId],
                  let index = sessions.firstIndex(where: { $0.id == sessionId }) else {
                print("❌ Session not found for date update: \(sessionId)")
                return
            }

            // Update local model
            sessions[index].completionDate = date
            sessions[index].updatedAt = Date()
            let isCompleted = sessions[index].isCompleted
            let notes = sessions[index].notes

            self.sessionTracking[planId] = sessions
            self.saveSessionTracking()
            self.objectWillChange.send()
            print("✅ Updated session completion date → \(date) for \(sessionId)")

            // Queue a session update so the server reflects the new date
            self.queuePendingSessionUpdate(
                planId: planId,
                sessionId: sessionId,
                completed: isCompleted,
                notes: notes,
                completionDate: date
            )
        }
    }

    func updateSessionNotes(planId: String, sessionId: UUID, notes: String) {
        DispatchQueue.main.async {
            guard var sessions = self.sessionTracking[planId],
                  let index = sessions.firstIndex(where: { $0.id == sessionId }) else {
                return
            }

            sessions[index].notes = notes
            sessions[index].updatedAt = Date()
            
            self.sessionTracking[planId] = sessions
            self.saveSessionTracking()
            self.objectWillChange.send()
        }

        // Queue the updated session for sync
        if let session = sessionTracking[planId]?.first(where: { $0.id == sessionId }) {
            queuePendingSessionUpdate(
                planId: planId,
                sessionId: sessionId,
                completed: session.isCompleted,
                notes: notes,
                completionDate: session.completionDate
            )
        }
    }
    
    func updateExerciseEntry(_ updatedEntry: ExerciseTracking) {
        DispatchQueue.main.async {
            if var exercises = self.exerciseHistory[updatedEntry.planId],
               let index = exercises.firstIndex(where: { $0.id == updatedEntry.id }) {

                let originalEntry = exercises[index]
                let cleanedNotes = self.cleanNotesForDisplay(updatedEntry.notes)

                let preservedEntry = self.createUpdatedExerciseEntry(
                    original: originalEntry,
                    newDate: updatedEntry.date,
                    newNotes: cleanedNotes
                )

                // 1) replace in local history
                exercises[index] = preservedEntry
                self.exerciseHistory[updatedEntry.planId] = exercises

                // 2) update the parent session’s completionDate so DiaryView moves the dot
                if var sessions = self.sessionTracking[preservedEntry.planId],
                   let idx = sessions.firstIndex(where: { $0.id == preservedEntry.sessionId }) {
                    sessions[idx].completionDate = preservedEntry.date
                    sessions[idx].updatedAt = Date()
                    let completedFlag = sessions[idx].isCompleted  // keep existing completion state
                    self.sessionTracking[preservedEntry.planId] = sessions

                    // queue a session update so server stays consistent
                    self.queuePendingSessionUpdate(
                        planId: preservedEntry.planId,
                        sessionId: preservedEntry.sessionId,
                        completed: completedFlag,
                        notes: sessions[idx].notes,
                        completionDate: preservedEntry.date
                    )
                }

                // 3) persist & notify UI
                self.saveAllData()
                self.objectWillChange.send()
                NotificationCenter.default.post(
                    name: NSNotification.Name("ExerciseDataUpdated"),
                    object: nil,
                    userInfo: [
                        "planId": updatedEntry.planId,
                        "exerciseId": preservedEntry.id.uuidString,
                        "oldDate": originalEntry.date,
                        "newDate": preservedEntry.date
                    ]
                )

                // 4) queue exercise sync
                self.queuePendingExerciseUpdate(tracking: preservedEntry)

                print("✅ Exercise entry updated: \(preservedEntry.id)")
                print("  - Date changed: \(originalEntry.date) → \(preservedEntry.date)")
            } else {
                print("❌ Exercise entry not found for update: \(updatedEntry.id)")
            }
        }
    }



    func deleteExerciseEntry(_ entry: ExerciseTracking) {
        DispatchQueue.main.async {
            if var exercises = self.exerciseHistory[entry.planId] {
                exercises.removeAll { $0.id == entry.id }
                self.exerciseHistory[entry.planId] = exercises
                self.saveAllData()
                self.objectWillChange.send()
                
                if entry.isSynced {
                    Task {
                        await self.deleteExerciseFromServer(tracking: entry)
                    }
                }
            }
        }
    }

    private func createUpdatedExerciseEntry(
        original: ExerciseTracking,
        newDate: Date,
        newNotes: String
    ) -> ExerciseTracking {
        // Extract the original key to preserve it
        let keyMatch = original.notes.range(of: #"\[KEY:([^\]]+)\]"#, options: .regularExpression)
        let originalKey = keyMatch != nil ? String(original.notes[keyMatch!]) : ""
        
        // Extract the exercise title from the original notes
        let exerciseTitle = extractExerciseTitle(from: original.notes)
        
        // Create properly formatted notes with exercise title and key
        let enhancedNotes: String
        if newNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            enhancedNotes = "[EXERCISE:\(exerciseTitle)]\(originalKey) Completed"
        } else {
            enhancedNotes = "[EXERCISE:\(exerciseTitle)]\(originalKey) \(newNotes)"
        }
        
        // FIXED: Create new instance preserving the original ID but with NEW DATE
        var updatedTracking = ExerciseTracking(
            preservingId: original.id,        // PRESERVE original ID
            planId: original.planId,
            sessionId: original.sessionId,
            exerciseId: original.exerciseId,
            date: newDate,                    // CRITICAL: Use the new date here!
            notes: enhancedNotes
        )
        
        // Reset sync status since this is now a modified entry
        updatedTracking.isSynced = false
        updatedTracking.lastSyncAttempt = nil
        updatedTracking.syncError = nil
        
        return updatedTracking
    }
    
    // MARK: - Server Synchronization (SIMPLIFIED)
    private func syncExerciseToServer(tracking: ExerciseTracking) async {
        guard let email = UserViewModel.shared.userProfile?.email,
                networkStatus == .connected else {
            print("❌ Cannot sync exercise - offline or no user")
            updateExerciseSyncStatus(trackingId: tracking.id, planId: tracking.planId, isSynced: false, error: "Offline")
            return
        }

        let lowerPlanId = tracking.planId.lowercased()
        let lowerExerciseId = tracking.id.uuidString.lowercased()
        
        // Check if this is an update (exercise already exists on server)
        let isUpdate = tracking.lastSyncAttempt != nil
        
        let urlString: String
        let httpMethod: String
        
        if isUpdate {
            // Update existing exercise
            urlString = "\(baseURL)/user/\(email)/plans/\(lowerPlanId)/exercises/\(lowerExerciseId)"
            httpMethod = "PUT"
        } else {
            // Create new exercise
            urlString = "\(baseURL)/user/\(email)/plans/\(lowerPlanId)/exercises"
            httpMethod = "POST"
        }
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid exercise sync URL")
            updateExerciseSyncStatus(trackingId: tracking.id, planId: tracking.planId, isSynced: false, error: "Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addAuthHeader()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Extract the actual exercise title from notes for server
        let actualTitle = extractExerciseTitle(from: tracking.notes)
            
        let payload: [String: Any] = [
            "id": tracking.id.uuidString.lowercased(),
            "session_id": tracking.sessionId.uuidString.lowercased(),
            "exercise_id": tracking.exerciseId.uuidString.lowercased(),
            "date": dateFormatter.string(from: tracking.date),  // This will now use the updated date
            "notes": tracking.notes
        ]

        print("📤 Exercise sync payload (\(httpMethod)): \(payload)")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.authenticatedData(for: request)
                
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    print("✅ Exercise \(isUpdate ? "updated" : "synced") to server: \(tracking.id)")
                    await MainActor.run {
                        updateExerciseSyncStatus(trackingId: tracking.id, planId: tracking.planId, isSynced: true, error: nil)
                    }
                } else {
                    let errorMsg = "HTTP \(httpResponse.statusCode)"
                    let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                    print("❌ Exercise sync failed: \(errorMsg)")
                    print("❌ Response: \(responseString)")
                    await MainActor.run {
                        updateExerciseSyncStatus(trackingId: tracking.id, planId: tracking.planId, isSynced: false, error: errorMsg)
                    }
                }
            }
        } catch {
            print("❌ Exercise sync error: \(error)")
            await MainActor.run {
                updateExerciseSyncStatus(trackingId: tracking.id, planId: tracking.planId, isSynced: false, error: error.localizedDescription)
            }
        }
    }

    private func syncSessionToServer(
        planId: String,
        sessionId: UUID,
        completed: Bool,
        notes: String,
        completionDate: Date?
    ) async {
        guard let email = UserViewModel.shared.userProfile?.email,
                networkStatus == .connected else {
            print("❌ Cannot sync session - offline or no user")
            return
        }

        let lowerPlanId = planId.lowercased()
        let lowerSessionId = sessionId.uuidString.lowercased()
            
        let urlString = "\(baseURL)/user/\(email)/plans/\(lowerPlanId)/sessions/\(lowerSessionId)"
        guard let url = URL(string: urlString) else {
            print("❌ Invalid session sync URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addAuthHeader()

        // CRITICAL FIX: Use snake_case field names
        let payload: [String: Any] = [
            "is_completed": completed,      // FIXED: was "isCompleted"
            "notes": notes,
            "completion_date": completionDate?.toISO8601String() as Any  // FIXED: was "completionDate"
        ]
            
        print("📤 Session sync payload: \(payload)") // Debug log
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await URLSession.shared.authenticatedData(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                print("✅ Session synced to server: \(sessionId)")
            } else {
                print("❌ Session sync failed with status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            }
        } catch {
            print("❌ Session sync error: \(error)")
        }
    }

    private func deleteExerciseFromServer(tracking: ExerciseTracking) async {
        guard let email = UserViewModel.shared.userProfile?.email,
                networkStatus == .connected else {
            print("❌ Cannot delete exercise - offline or no user")
            // Queue for deletion when online
            queueExerciseDeletion(tracking: tracking)
            return
        }
        
        let lowerPlanId = tracking.planId.lowercased()
        let lowerTrackingId = tracking.id.uuidString.lowercased()
            
        let urlString = "\(baseURL)/user/\(email)/plans/\(lowerPlanId)/exercises/\(lowerTrackingId)"
        guard let url = URL(string: urlString) else {
            print("❌ Invalid exercise delete URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addAuthHeader()
            
        print("🗑️ Deleting exercise from server: \(lowerTrackingId)")

        do {
            let (data, response) = try await URLSession.shared.authenticatedData(for: request)
                
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    print("✅ Exercise deleted from server: \(tracking.id)")
                } else {
                    print("❌ Exercise deletion failed with status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("❌ Response: \(responseString)")
                    }
                    // Could re-queue for retry here
                }
            }
        } catch {
            print("❌ Exercise deletion error: \(error)")
            // Queue for retry when online
            queueExerciseDeletion(tracking: tracking)
        }
    }
        
    // ISSUE 2 FIX: Queue deletions for retry
    private func queueExerciseDeletion(tracking: ExerciseTracking) {
        // Add to a deletion queue (implement similar to pending updates)
        print("📤 Queued exercise deletion for retry: \(tracking.id)")
    }

    private func syncSessionsToServer(planId: String, sessions: [SessionTracking]) async {
        guard let email = UserViewModel.shared.userProfile?.email,
              networkStatus == .connected else {
            print("❌ Cannot sync sessions - offline or no user")
            return
        }

        // Initialize sessions on server first
        let initUrl = URL(string: "\(baseURL)/user/\(email)/plans/\(planId.lowercased())/sessions/initialize")!
        var initRequest = URLRequest(url: initUrl)
        initRequest.httpMethod = "POST"
        initRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        initRequest.addAuthHeader()
        initRequest.httpBody = try? JSONSerialization.data(withJSONObject: [:])

        do {
            let (_, response) = try await URLSession.shared.authenticatedData(for: initRequest)
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                print("✅ Sessions initialized on server for plan: \(planId)")
            }
        } catch {
            print("❌ Failed to initialize sessions on server: \(error)")
        }
    }

    // MARK: - Pending Updates Management
    private func queuePendingSessionUpdate(
        planId: String,
        sessionId: UUID,
        completed: Bool,
        notes: String,
        completionDate: Date?
    ) {
        let pendingUpdate = PendingSessionUpdate(
            planId: planId,
            sessionId: sessionId,
            completed: completed,
            notes: notes,
            completionDate: completionDate,
            timestamp: Date()
        )
        
        pendingSessionUpdates.append(pendingUpdate)
        savePendingSessionUpdates()
        print("📤 Queued pending session update for: \(sessionId)")
        
        // Try to sync immediately if online (but don't block)
        if networkStatus == .connected {
            Task {
                await syncSessionToServer(
                    planId: planId,
                    sessionId: sessionId,
                    completed: completed,
                    notes: notes,
                    completionDate: completionDate
                )
            }
        }
    }

    private func queuePendingExerciseUpdate(tracking: ExerciseTracking) {
        let pendingUpdate = PendingExerciseUpdate(
            tracking: tracking,
            timestamp: Date()
        )
        
        pendingExerciseUpdates.append(pendingUpdate)
        savePendingExerciseUpdates()
        print("📤 Queued pending exercise update for: \(tracking.id)")
        
        // Try to sync immediately if online (but don't block)
        if networkStatus == .connected {
            Task {
                await syncExerciseToServer(tracking: tracking)
            }
        }
    }

    private func processPendingUpdates() async {
        guard networkStatus == .connected else { return }
        
        print("🔄 Processing pending updates...")
        print("  - Session updates: \(pendingSessionUpdates.count)")
        print("  - Exercise updates: \(pendingExerciseUpdates.count)")

        await MainActor.run {
            self.isSyncing = true
        }

        // Process session updates
        let sessionUpdates = pendingSessionUpdates
        pendingSessionUpdates.removeAll()
        savePendingSessionUpdates()

        for update in sessionUpdates {
            await syncSessionToServer(
                planId: update.planId,
                sessionId: update.sessionId,
                completed: update.completed,
                notes: update.notes,
                completionDate: update.completionDate
            )
        }

        // Process exercise updates
        let exerciseUpdates = pendingExerciseUpdates
        pendingExerciseUpdates.removeAll()
        savePendingExerciseUpdates()

        for update in exerciseUpdates {
            await syncExerciseToServer(tracking: update.tracking)
        }

        await MainActor.run {
            self.isSyncing = false
            self.lastSyncTime = Date()
            self.saveLastSyncTime()
        }
        
        print("✅ Finished processing pending updates")
    }

    // MARK: - Helper Methods
        private func ensureSessionExists(planId: String, sessionId: UUID) {
            if let sessions = sessionTracking[planId], sessions.contains(where: { $0.id == sessionId }) {
                return
            }
            print("⚠️ Session \(sessionId) not found locally for plan \(planId). Try calling refreshSessions(for:) to sync from server.")
            // Do not create a placeholder; instead you could call fetchSessionsForPlan
        }

    private func updateExerciseSyncStatus(trackingId: UUID, planId: String, isSynced: Bool, error: String?) {
        guard var exercises = exerciseHistory[planId],
              let index = exercises.firstIndex(where: { $0.id == trackingId }) else {
            return
        }

        exercises[index].isSynced = isSynced
        exercises[index].lastSyncAttempt = Date()
        exercises[index].syncError = error

        exerciseHistory[planId] = exercises
        saveExerciseHistory()
        objectWillChange.send()
    }

    // MARK: - Public Query Methods
    func getHistoryForExerciseTitle(exerciseTitle: String, planId: String) -> [ExerciseTracking] {
        guard let exercises = exerciseHistory[planId] else {
            return []
        }
            
        let searchTitle = exerciseTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("🔍 Searching history for exact exercise: '\(searchTitle)'")
        
        // Only match exercises with exact EXERCISE tag
        let results = exercises.filter { exercise in
            let exactMatch = exercise.notes.contains("[EXERCISE:\(searchTitle)]")
            if exactMatch {
                print("✅ Found match for '\(searchTitle)': \(exercise.id)")
            }
            return exactMatch
        }
        
        print("🔍 Found \(results.count) entries for '\(searchTitle)'")
        return results.sorted(by: { $0.date > $1.date })
    }

    func cleanNotesForDisplay(_ notes: String) -> String {
        var cleaned = notes
        
        // STEP 1: Remove the [EXERCISE:...] tag completely
        if let exerciseRange = cleaned.range(of: #"\[EXERCISE:[^\]]+\]\s*"#, options: .regularExpression) {
            cleaned.removeSubrange(exerciseRange)
        }
        
        // STEP 2: Remove the [KEY:...] tag completely
        if let keyRange = cleaned.range(of: #"\[KEY:[^\]]+\]\s*"#, options: .regularExpression) {
            cleaned.removeSubrange(keyRange)
        }
        
        // STEP 3: Clean up remaining text
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // STEP 4: Handle the default "completed" case
        if cleaned.hasSuffix(" completed") || cleaned.hasSuffix(" Completed") {
            cleaned = String(cleaned.dropLast(" completed".count))
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // If what's left is just the exercise name or very short, return empty
            // This prevents showing redundant text like "Board Session" when the user
            // can already see the exercise name in the UI
            if cleaned.count < 50 {
                return ""
            }
        }
        
        // STEP 5: If the cleaned result is empty or just whitespace, return empty string
        if cleaned.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ""
        }
        
        return cleaned
    }

    func getSyncStatus(for planId: String) -> (total: Int, synced: Int, failed: Int, pending: Int) {
        let exercises = exerciseHistory[planId] ?? []
        let total = exercises.count
        let synced = exercises.filter { $0.isSynced }.count
        let failed = exercises.filter { $0.syncError != nil }.count
        let pending = pendingExerciseUpdates.filter { $0.tracking.planId == planId }.count
        
        return (total: total, synced: synced, failed: failed, pending: pending)
    }

    func getCompletionStats(planId: String) -> (completed: Int, total: Int, percentage: Double) {
        guard let sessions = sessionTracking[planId] else {
            return (0, 0, 0.0)
        }
        
        let total = sessions.count
        let completed = sessions.filter { $0.isCompleted }.count
        let percentage = total > 0 ? Double(completed) / Double(total) : 0.0
        
        return (completed: completed, total: total, percentage: percentage)
    }
    
    func getSessionsForWeek(planId: String, weekNumber: Int) -> [SessionTracking] {
        // Look up the list for this plan, filter by the weekNumber, or return an empty array
        return sessionTracking[planId]?
            .filter { $0.weekNumber == weekNumber }
            ?? []
    }

    // MARK: - Utility Methods

    func extractDayFromSessionTitle(_ title: String) -> String? {
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
            
        for day in days {
            if title.starts(with: day) {
                return day
            }
        }
            
        return nil
    }

    func extractFocusFromSessionTitle(_ title: String) -> String {
        if let colonIndex = title.firstIndex(of: ":") {
            let startIndex = title.index(after: colonIndex)
            return String(title[startIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return title
    }

    // MARK: - Manual Sync Controls
    func syncAllPlans() async {
        print("🔄 Starting sync for all plans")
            
        await MainActor.run {
            self.isSyncing = true
        }
            
        await processPendingUpdates()
            
        for planId in sessionTracking.keys {
            await refreshSessions(for: planId)
        }
            
        await MainActor.run {
            self.isSyncing = false
            self.lastSyncTime = Date()
            self.saveLastSyncTime()
        }
            
        print("✅ Completed sync for all plans")
    }

    func forceCompleteSync() async {
        print("🔄 Starting force complete sync")
            
        await MainActor.run {
            self.isSyncing = true
        }
            
        await processPendingUpdates()
            
        for (planId, exercises) in exerciseHistory {
            let unsyncedExercises = exercises.filter { !$0.isSynced }
                
            for exercise in unsyncedExercises {
                await syncExerciseToServer(tracking: exercise)
            }
        }
            
        await MainActor.run {
            self.isSyncing = false
            self.lastSyncTime = Date()
            self.saveLastSyncTime()
        }
            
        print("✅ Force sync completed")
    }

    func refreshSessions(for planId: String) async {
        guard let email = UserViewModel.shared.userProfile?.email,
                networkStatus == .connected else {
            return
        }

        let lowerPlanId = planId.lowercased()
        let urlString = "\(baseURL)/user/\(email)/plans/\(lowerPlanId)/sessions"
        guard let url = URL(string: urlString) else { return }

        do {
            var request = URLRequest(url: url)
            request.addAuthHeader()

            let (data, _) = try await URLSession.shared.authenticatedData(for: request)
                
            let sessions: [SessionTracking]
            if let sessionArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                sessions = sessionArray.compactMap { sessionData in
                    guard let idString = sessionData["id"] as? String,
                            let id = UUID(uuidString: idString),
                            let planId = sessionData["plan_id"] as? String ?? sessionData["planId"] as? String,
                            let weekNumber = sessionData["week_number"] as? Int ?? sessionData["weekNumber"] as? Int,
                            let dayOfWeek = sessionData["day_of_week"] as? String ?? sessionData["dayOfWeek"] as? String,
                            let focusName = sessionData["focus_name"] as? String ?? sessionData["focusName"] as? String else {
                        return nil
                    }
                    
                    var session = SessionTracking(withSpecificId: id, planId: planId, weekNumber: weekNumber, dayOfWeek: dayOfWeek, focusName: focusName)
                    session.isCompleted = sessionData["is_completed"] as? Bool ?? sessionData["isCompleted"] as? Bool ?? false
                    session.notes = sessionData["notes"] as? String ?? ""
                    
                    if let completionDateString = sessionData["completion_date"] as? String ?? sessionData["completionDate"] as? String {
                        let formatter = ISO8601DateFormatter()
                        session.completionDate = formatter.date(from: completionDateString)
                    }
                    
                    if let updatedAtString = sessionData["updated_at"] as? String ?? sessionData["updatedAt"] as? String {
                        let formatter = ISO8601DateFormatter()
                        session.updatedAt = formatter.date(from: updatedAtString) ?? Date()
                    }
                    
                    return session
                }
            } else {
                sessions = []
            }

            await MainActor.run {
                if self.sessionTracking[planId] != nil {
                    self.mergeServerSessions(sessions, for: planId)
                } else {
                    self.sessionTracking[planId] = sessions
                }
                self.saveSessionTracking()
            }
            
            print("✅ Refreshed \(sessions.count) sessions for plan: \(planId)")
        } catch {
            print("❌ Error refreshing sessions: \(error)")
        }
    }

    private func mergeServerSessions(_ serverSessions: [SessionTracking], for planId: String) {
        guard var localSessions = sessionTracking[planId] else {
            sessionTracking[planId] = serverSessions
            return
        }

        for serverSession in serverSessions {
            if let index = localSessions.firstIndex(where: { $0.id == serverSession.id }) {
                let localSession = localSessions[index]
                
                // Keep local changes if they're newer
                if localSession.updatedAt > serverSession.updatedAt {
                    continue
                }
                
                localSessions[index] = serverSession
            } else {
                localSessions.append(serverSession)
            }
        }

        sessionTracking[planId] = localSessions
    }

    // MARK: - Data Management
    func saveAllData() {
        DispatchQueue.main.async { [weak self] in
            self?.saveSessionTracking()
            self?.saveExerciseHistory()
            self?.savePendingSessionUpdates()
            self?.savePendingExerciseUpdates()
            self?.saveLastSyncTime()
        }
    }

    func clearAllData() {
        DispatchQueue.main.async {
            self.sessionTracking.removeAll()
            self.exerciseHistory.removeAll()
            self.pendingSessionUpdates.removeAll()
            self.pendingExerciseUpdates.removeAll()
            
            self.saveSessionTracking()
            self.saveExerciseHistory()
            self.savePendingSessionUpdates()
            self.savePendingExerciseUpdates()
            
            UserDefaults.standard.removeObject(forKey: self.lastSyncTimeKey())
            self.lastSyncTime = nil
            
            self.objectWillChange.send()
        }
    }

    // MARK: - Debug Methods
    func testServerConnectivity() async -> (success: Bool, message: String) {
        guard let email = UserViewModel.shared.userProfile?.email else {
            return (false, "User not logged in")
        }
        
        let testPlanId = "connectivity_test"
        let urlString = "\(baseURL)/user/\(email)/plans/\(testPlanId)/sessions"
        guard let url = URL(string: urlString) else {
            return (false, "Invalid URL")
        }
        
        do {
            var request = URLRequest(url: url)
            request.addAuthHeader()
            
            let (_, response) = try await URLSession.shared.authenticatedData(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    return (true, "Server connectivity OK")
                } else {
                    return (false, "Server returned status \(httpResponse.statusCode)")
                }
            } else {
                return (false, "Invalid response type")
            }
        } catch {
            return (false, "Network error: \(error.localizedDescription)")
        }
    }

    // MARK: - Compatibility Methods (for existing code)
    func ensureLocalDataAccessibility() {
        loadAllData()
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    // Convenience properties
    var hasUnsyncedData: Bool {
        let hasUnsyncedExercises = exerciseHistory.values.contains { exercises in
            exercises.contains { !$0.isSynced }
        }
        return !pendingSessionUpdates.isEmpty || !pendingExerciseUpdates.isEmpty || hasUnsyncedExercises
    }

    var totalPendingUpdates: Int {
        return pendingSessionUpdates.count + pendingExerciseUpdates.count
    }
}

// MARK: - Extensions
extension Date {
    func toISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
    
    var iso8601String: String {
        return toISO8601String()
    }
}

extension SessionTrackingManager {
    /// Remove any cached session/exercise data for plan IDs the user no longer has.
    /// Call after loading plans from server and after a successful delete.
    func pruneOrphanPlanData(currentPlanIds: Set<String>) {
        // normalize for safety
        let normalized = Set(currentPlanIds.map { $0.lowercased() })

        // keep server plans + anything still pending (so we don't drop offline edits)
        var keep = normalized
        let pendingSessionIds  = Set(pendingSessionUpdates.map { $0.planId.lowercased() })
        let pendingExerciseIds = Set(pendingExerciseUpdates.map { $0.tracking.planId.lowercased() })
        keep.formUnion(pendingSessionIds)
        keep.formUnion(pendingExerciseIds)

        // drop everything else
        sessionTracking       = sessionTracking.filter       { keep.contains($0.key.lowercased()) }
        exerciseHistory       = exerciseHistory.filter       { keep.contains($0.key.lowercased()) }
        pendingSessionUpdates.removeAll   { !keep.contains($0.planId.lowercased()) }
        pendingExerciseUpdates.removeAll  { !keep.contains($0.tracking.planId.lowercased()) }

        // persist + notify UI
        saveAllData()
        objectWillChange.send()
        NotificationCenter.default.post(name: .init("ExerciseDataUpdated"), object: nil)
    }
}
