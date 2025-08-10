//
//  DiaryView.swift
//  Ascendify
//
//  Created by Ellis Barker on 27/05/2025.
//

import SwiftUI

// MARK: - Diary Entry Types
enum DiaryEntryType {
    case training(sessionId: UUID, planId: String)
    case projectLog(logEntry: LogEntry, projectName: String)
    case dailyNote(note: DailyNote)
    
    var color: Color {
        switch self {
        case .training: return .blue
        case .projectLog: return .green
        case .dailyNote: return .purple
        }
    }
    
    var iconName: String {
        switch self {
        case .training: return "figure.climbing"
        case .projectLog: return "flag.fill"
        case .dailyNote: return "note.text"
        }
    }
}

// MARK: - Daily Note Model
struct DailyNote: Identifiable, Codable {
    let id: UUID
    let date: Date
    var content: String
    let createdAt: Date
    var updatedAt: Date?
    
    // Local tracking for sync status
    var isSynced: Bool = true
    var syncError: String? = nil
    
    init(id: UUID = UUID(), date: Date, content: String) {
        self.id = id
        self.date = date
        self.content = content
        self.createdAt = Date()
        self.updatedAt = nil
        self.isSynced = false // New notes start unsynced
    }
    
    // For decoding from server
    init(from serverNote: DailyNoteServer) {
        self.id = UUID(uuidString: serverNote.id) ?? UUID()
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        dayFormatter.timeZone = TimeZone.current

        self.date = dayFormatter.date(from: serverNote.date) ?? Date()
        
        // parse full ISO-8601 datetimes
        let iso = ISO8601DateFormatter()
        self.createdAt = iso.date(from: serverNote.createdAt) ?? Date()  // changed
        if let u = serverNote.updatedAt {  // changed
            self.updatedAt = iso.date(from: u)
        } else {
            self.updatedAt = nil
        }

        self.content = serverNote.content
        self.isSynced = true
    }
}

// MARK: - Server Response Models
struct DailyNoteServer: Codable {
    let id: String
    let date: String
    let content: String
    let createdAt: String
    let updatedAt: String?
}

struct DailyNoteCreateRequest: Codable {
    let date: String
    let content: String
}

struct DailyNoteUpdateRequest: Codable {
    let content: String
}

// MARK: - Calendar Day Model
struct CalendarDay: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    var entries: [DiaryEntryType] = []
    
    var hasTraining: Bool {
        entries.contains { entry in
            if case .training = entry { return true }
            return false
        }
    }
    
    var hasProjectLog: Bool {
        entries.contains { entry in
            if case .projectLog = entry { return true }
            return false
        }
    }
    
    var hasDailyNote: Bool {
        entries.contains { entry in
            if case .dailyNote = entry { return true }
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        lhs.id == rhs.id
    }
}

// Wrapper for optional calendar days in ForEach
struct CalendarDayWrapper: Identifiable {
    let id = UUID()
    let day: CalendarDay?
}

// MARK: - Diary Manager
class DiaryManager: ObservableObject {
    static let shared = DiaryManager()

    @Published var dailyNotes: [DailyNote] = []
    @Published var isSyncing = false
    @Published var syncError: String? = nil

    private var currentUserEmail: String?
    private let baseURL = "http://127.0.0.1:8001"

    // Compute a per‑user key.  If email isn’t set, don’t load or save anything.
    private func storageKey() -> String? {
        guard let email = currentUserEmail else { return nil }
        return "diary_daily_notes_\(email.lowercased())"
    }

    // Call this when the user signs in
    func setCurrentUser(email: String) {
        currentUserEmail = email.lowercased()
        dailyNotes = []           // clear in‑memory notes immediately
        loadDailyNotes()          // load the signed‑in user’s notes
        Task { await syncDailyNotes() }  // optional: refresh from server
    }

    // Call this on sign‑out
    func clearForSignOut() {
        if let key = storageKey() {
            UserDefaults.standard.removeObject(forKey: key)
        }
        dailyNotes = []
        currentUserEmail = nil
    }

    // Use the computed key when loading notes
    private func loadDailyNotes() {
        guard let key = storageKey() else {
            dailyNotes = []
            return
        }
        if let data = UserDefaults.standard.data(forKey: key) {
            dailyNotes = (try? JSONDecoder().decode([DailyNote].self, from: data)) ?? []
        } else {
            dailyNotes = []
        }
    }

    // Use the computed key when saving notes
    private func saveDailyNotes() {
        guard let key = storageKey(),
              let data = try? JSONEncoder().encode(dailyNotes) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    // MARK: - Server Sync

    @MainActor
    func syncDailyNotes() async {
        guard let email = UserViewModel.shared.userProfile?.email else { return }

        isSyncing = true
        syncError = nil

        do {
            let url = URL(string: "\(baseURL)/daily_notes/\(email)")!
            var request = URLRequest(url: url)
            request.addAuthHeader()

            // Use authenticated request
            let (data, _) = try await URLSession.shared.authenticatedData(for: request)

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            let serverNotes = try decoder.decode([DailyNoteServer].self, from: data)

            var mergedNotes: [DailyNote] = []
            var serverNoteIds = Set<String>()

            // 1) Add all server notes to merged list
            for serverNote in serverNotes {
                serverNoteIds.insert(serverNote.id.lowercased()) // normalize IDs
                mergedNotes.append(DailyNote(from: serverNote))
            }

            // 2) Push any local unsynced notes that aren’t on the server yet
            for localNote in dailyNotes
            where !serverNoteIds.contains(localNote.id.uuidString.lowercased()) && !localNote.isSynced {
                await createNoteOnServer(localNote)
            }

            // 3) Ensure local unsynced notes stay visible immediately
            let localUnsynced = dailyNotes.filter {
                !serverNoteIds.contains($0.id.uuidString.lowercased()) && !$0.isSynced
            }
            mergedNotes.append(contentsOf: localUnsynced)

            // 4) Publish + persist
            self.dailyNotes = mergedNotes
            self.saveDailyNotes()

        } catch {
            print("❌ Daily notes sync error: \(error)")
            print("❌ Error type: \(type(of: error))")
            syncError = "Failed to sync notes: \(error.localizedDescription)"
        }

        isSyncing = false
    }
    
    // MARK: - Daily Notes Management
    func addDailyNote(date: Date, content: String) {
        let note = DailyNote(date: date, content: content)
        dailyNotes.append(note)
        saveDailyNotes()
        
        // Sync to server
        Task {
            await createNoteOnServer(note)
        }
    }
    
    func updateDailyNote(_ note: DailyNote, newContent: String) {
        if let index = dailyNotes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.content = newContent
            updatedNote.updatedAt = Date()
            updatedNote.isSynced = false
            dailyNotes[index] = updatedNote
            saveDailyNotes()
            
            // Sync to server
            Task {
                await updateNoteOnServer(updatedNote)
            }
        }
    }
    
    func deleteDailyNote(_ note: DailyNote) {
        // Delete from server
        Task {
            await deleteNoteOnServer(note)
        }
    }
    
    // MARK: - Server Operations
    @MainActor
    private func createNoteOnServer(_ note: DailyNote) async {
        guard let email = UserViewModel.shared.userProfile?.email else { return }

        // Lowercase ID for consistency (even though it's not in the URL)
        let _ = note.id.uuidString.lowercased()

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        dayFormatter.timeZone = TimeZone.current
        let dateString = dayFormatter.string(from: note.date)

        do {
            let url = URL(string: "\(baseURL)/daily_notes/\(email)")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addAuthHeader()

            let payload = DailyNoteCreateRequest(
                date:    dateString,
                content: note.content
            )

            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(payload)

            let (_, response) = try await URLSession.shared.authenticatedData(for: request)

            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                // Update local note as synced
                if let index = dailyNotes.firstIndex(where: { $0.id == note.id }) {
                    dailyNotes[index].isSynced = true
                    dailyNotes[index].syncError = nil
                    saveDailyNotes()
                }
                print("✅ Daily note created on server")
            } else {
                print("❌ Failed to create note on server")
            }
        } catch {
            print("❌ Error creating note on server: \(error)")
            // Mark note as having sync error
            if let index = dailyNotes.firstIndex(where: { $0.id == note.id }) {
                dailyNotes[index].syncError = error.localizedDescription
                saveDailyNotes()
            }
        }
    }

    
    // MARK: - Server Update

    @MainActor
    private func updateNoteOnServer(_ note: DailyNote) async {
        guard let email = UserViewModel.shared.userProfile?.email else { return }

        do {
            let noteIdString = note.id.uuidString.lowercased()
            let url = URL(string: "\(baseURL)/daily_notes/\(email)/\(noteIdString)")!
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addAuthHeader()
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(note)

            let (_, response) = try await URLSession.shared.authenticatedData(for: request)

            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                if let index = dailyNotes.firstIndex(where: { $0.id == note.id }) {
                    dailyNotes[index].isSynced = true
                }
                saveDailyNotes()
            } else {
                print("❌ Failed to update note on server")
            }
        } catch {
            print("❌ Error updating note on server: \(error)")
        }
    }

    // MARK: - Server Delete

    @MainActor
    private func deleteNoteOnServer(_ note: DailyNote) async {
        guard let email = UserViewModel.shared.userProfile?.email else { return }

        do {
            let noteIdString = note.id.uuidString.lowercased()
            let url = URL(string: "\(baseURL)/daily_notes/\(email)/\(noteIdString)")!
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.addAuthHeader()

            let (_, response) = try await URLSession.shared.authenticatedData(for: request)

            if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                print("✅ Note deleted on server")
            } else {
                print("❌ Failed to delete note on server")
            }
        } catch {
            print("❌ Error deleting note on server: \(error)")
        }
    }

    
    // MARK: - Get All Entries for a Date
    func getEntriesForDate(_ date: Date) -> [DiaryEntryType] {
        var entries: [DiaryEntryType] = []
        let calendar = Calendar.current
        
        // Get training sessions
        let sessionManager = SessionTrackingManager.shared
        for (planId, sessions) in sessionManager.sessionTracking {
            for session in sessions where session.isCompleted {
                if let completionDate = session.completionDate,
                   calendar.isDate(completionDate, inSameDayAs: date) {
                    entries.append(.training(sessionId: session.id, planId: planId))
                }
            }
        }
        
        // Get project logs
        let projectsManager = ProjectsManager.shared
        for project in projectsManager.projects {
            for logEntry in project.logEntries {
                if calendar.isDate(logEntry.dateObject, inSameDayAs: date) {
                    entries.append(.projectLog(logEntry: logEntry, projectName: project.routeName))
                }
            }
        }
        // Get daily notes
        for note in dailyNotes {
            if calendar.isDate(note.date, inSameDayAs: date) {
                entries.append(.dailyNote(note: note))
            }
        }
            
        return entries
    }
    
    // MARK: - Get Calendar Days for Month
    func getCalendarDaysForMonth(date: Date) -> [CalendarDay] {
        let calendar = Calendar.current
        guard let monthRange = calendar.range(of: .day, in: .month, for: date) else { return [] }
        
        let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
        
        return monthRange.compactMap { day -> CalendarDay? in
            guard let dayDate = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) else { return nil }
            
            let entries = getEntriesForDate(dayDate)
            return CalendarDay(date: dayDate, entries: entries)
        }
    }
}

// MARK: - Main Diary View
struct DiaryView: View {
    @StateObject private var diaryManager = DiaryManager.shared
    @State private var selectedDate = Date()
    @State private var showingDayDetail = false
    @State private var showingAddNote = false
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
            VStack(spacing: 0) {
                HeaderView()
                
                if diaryManager.isSyncing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Syncing...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Month Navigation
                        monthNavigationView
                        
                        // Calendar Grid
                        calendarGridView
                        
                        // Legend
                        legendView
                        
                        // Sync status
                        if let syncError = diaryManager.syncError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text(syncError)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await diaryManager.syncDailyNotes()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingDayDetail) {
                DayDetailView(date: selectedDate)
            }
            .sheet(isPresented: $showingAddNote) {
                AddNoteView(date: selectedDate) {
                    // Refresh after adding note
                    diaryManager.objectWillChange.send()
                }
            }
            .onAppear {
                diaryManager.setupExerciseUpdateListener()
            }
            // <-- New listener to force a refresh when exercises move
            .onReceive(
                NotificationCenter
                    .default
                    .publisher(for: .init("ExerciseDataUpdated")),
                perform: { _ in
                    diaryManager.objectWillChange.send()
                }
            )
        }
    
    // MARK: - Month Navigation
    private var monthNavigationView: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.tealBlue)
            }
            
            Spacer()
            
            Text(dateFormatter.string(from: currentMonth))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.deepPurple)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.tealBlue)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Calendar Grid
    private var calendarGridView: some View {
        let days = diaryManager.getCalendarDaysForMonth(date: currentMonth)
        let columns = Array(repeating: GridItem(.flexible()), count: 7)
        
        return VStack(spacing: 10) {
            // Weekday headers
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar days
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(getDaysWithPaddingWrapped(days: days)) { wrapper in
                    if let day = wrapper.day {
                        CalendarDayView(day: day) {
                            selectedDate = day.date
                            showingDayDetail = true
                        }
                    } else {
                        Color.clear
                            .frame(height: 50)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Legend
    private var legendView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Legend")
                .font(.headline)
                .foregroundColor(.deepPurple)
            
            HStack(spacing: 20) {
                legendItem(color: .blue, text: "Training")
                legendItem(color: .green, text: "Project Log")
                legendItem(color: .purple, text: "Daily Note")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(text)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Helper Functions
    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
    
    private func getDaysWithPaddingWrapped(days: [CalendarDay]) -> [CalendarDayWrapper] {
        guard let firstDay = days.first else { return [] }
        
        let weekday = calendar.component(.weekday, from: firstDay.date)
        let padding = weekday - 1
        
        var wrappedDays: [CalendarDayWrapper] = []
        
        // Add padding days
        for _ in 0..<padding {
            wrappedDays.append(CalendarDayWrapper(day: nil))
        }
        
        // Add actual days
        for day in days {
            wrappedDays.append(CalendarDayWrapper(day: day))
        }
        
        return wrappedDays
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let day: CalendarDay
    let onTap: () -> Void
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: day.date)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isToday ? Color.tealBlue.opacity(0.2) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isToday ? Color.tealBlue : Color.clear, lineWidth: 2)
                    )
                
                VStack(spacing: 4) {
                    Text(dayNumber)
                        .font(.system(size: 14, weight: isToday ? .bold : .medium))
                        .foregroundColor(isToday ? .tealBlue : .primary)
                    
                    if !day.entries.isEmpty {
                        HStack(spacing: 2) {
                            if day.hasTraining {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 6, height: 6)
                            }
                            if day.hasProjectLog {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                            }
                            if day.hasDailyNote {
                                Circle()
                                    .fill(Color.purple)
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                }
            }
            .frame(height: 50)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Day Detail View
struct DayDetailView: View {
    let date: Date
    @StateObject private var diaryManager = DiaryManager.shared
    @StateObject private var sessionManager = SessionTrackingManager.shared
    @StateObject private var projectsManager = ProjectsManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddNote = false
    @State private var selectedTrainingSession: SessionTracking? = nil
    @State private var selectedPlanId: String? = nil
    @State private var showingSessionNotes = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }
    
    private var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom header with gradient
            headerSection
            
            ScrollView {
                VStack(spacing: 16) {
                    // Summary card at top
                    summaryCard
                    
                    // Entry cards
                    ForEach(Array(diaryManager.getEntriesForDate(date).enumerated()), id: \.offset) { _, entry in
                        entryCard(for: entry)
                    }
                    
                    if diaryManager.getEntriesForDate(date).isEmpty {
                        emptyStateView
                    }
                }
                .padding()
            }
            .background(Color(.systemGray6))
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddNote, onDismiss: {}) {
            // content:
            AddNoteView(date: date) {
                diaryManager.objectWillChange.send()
            }
        }
        .sheet(isPresented: $showingSessionNotes) {
            if let session = selectedTrainingSession, let plan = selectedPlanId {
                SessionExerciseNotesView(session: session, planId: plan)
            } else {
                // (Optional) fallback so the content always returns a View
                Text("No session selected")
            }
        }
    }
    
    private var headerSection: some View {
        ZStack {
            // Gradient background matching your app
            LinearGradient(
                gradient: Gradient(colors: [.ascendGreen, .vividPurple]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea(edges: .top)
            
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Close")
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                }
                
                Spacer()
                
                Text(shortDateFormatter.string(from: date))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showingAddNote = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.2))
                        )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .frame(height: 80)
    }
    
    private var summaryCard: some View {
        let entries = diaryManager.getEntriesForDate(date)
        let entryCount = entries.count
        
        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Day Summary")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.deepPurple)
                
                Text("\(entryCount) \(entryCount == 1 ? "entry" : "entries") recorded")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Activity indicators
            HStack(spacing: 12) {
                if entries.contains(where: { if case .training = $0 { return true }; return false }) {
                    VStack(spacing: 2) {
                        Image(systemName: "figure.climbing")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                        Text("Training")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                
                if entries.contains(where: { if case .projectLog = $0 { return true }; return false }) {
                    VStack(spacing: 2) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                        Text("Project")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                
                if entries.contains(where: { if case .dailyNote = $0 { return true }; return false }) {
                    VStack(spacing: 2) {
                        Image(systemName: "note.text")
                            .font(.system(size: 16))
                            .foregroundColor(.purple)
                        Text("Note")
                            .font(.caption2)
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.tealBlue.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No activities recorded")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Add a note to capture your thoughts about this day")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingAddNote = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Note")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.ascendGreen)
                )
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    private func entryCard(for entry: DiaryEntryType) -> some View {
        switch entry {
        case .training(let sessionId, let planId):
            if let sessions = sessionManager.sessionTracking[planId],
               let session = sessions.first(where: { $0.id == sessionId }) {
                Button(action: {
                    selectedTrainingSession = session
                    selectedPlanId = planId
                    showingSessionNotes = true
                }) {
                    TrainingEntryCard(session: session, planId: planId)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
        case .projectLog(let logEntry, let projectName):
            ProjectLogEntryCard(logEntry: logEntry, projectName: projectName)
            
        case .dailyNote(let note):
            DailyNoteCard(note: note)
        }
    }
}

// MARK: - Enhanced Training Entry Card
struct TrainingEntryCard: View {
    let session: SessionTracking
    let planId: String
    @StateObject private var trackingManager = SessionTrackingManager.shared
    
    private func routeDisplayName(from planId: String) -> String {
        let parts = planId.split(separator: "_")
        guard parts.count >= 2 else { return planId } // fallback if format is unexpected
        let grade = parts.last!
        let name = parts.dropLast()
            .map { String($0).capitalized }
            .joined(separator: " ")
        return "\(name) \(grade)"
    }
    
    private var exerciseCount: Int {
        trackingManager.exerciseHistory[planId]?
            .filter { $0.sessionId == session.id }
            .count ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "figure.climbing")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Training Session")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text("\(session.dayOfWeek), Week \(session.weekNumber)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if session.isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(session.focusName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // ROUTE CHIP – clearer + labeled
                HStack(spacing: 6) {
                    Image(systemName: "mountain.2.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                    Text("Route:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(routeDisplayName(from: planId))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.deepPurple)
                }
                .padding(.leading, 2) // 👈 this keeps chip aligned with focusName text
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(Color.purple.opacity(0.12))
                )
                .overlay(
                    Capsule().stroke(Color.purple.opacity(0.25), lineWidth: 1)
                )
                .accessibilityLabel("Route \(routeDisplayName(from: planId))")

                
                if exerciseCount > 0 {
                    HStack {
                        Image(systemName: "list.bullet")
                            .foregroundColor(.tealBlue)
                            .frame(width: 16)
                        Text("\(exerciseCount) exercises completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !session.notes.isEmpty {
                    HStack(alignment: .top) {
                        Image(systemName: "note.text")
                            .foregroundColor(.tealBlue)
                            .frame(width: 16)
                        Text(session.notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Enhanced Project Log Entry Card
struct ProjectLogEntryCard: View {
    let logEntry: LogEntry
    let projectName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "flag.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Project Log")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Text(projectName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let mood = logEntry.mood {
                    VStack(spacing: 4) {
                        Image(systemName: mood.iconName)
                            .font(.system(size: 20))
                            .foregroundColor(mood.color)
                        Text(mood.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundColor(mood.color)
                    }
                }
            }
            
            Text(logEntry.content)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(nil)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Enhanced Daily Note Card
struct DailyNoteCard: View {
    let note: DailyNote
    @StateObject private var diaryManager = DiaryManager.shared
    @State private var showingEditNote = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "note.text")
                            .font(.system(size: 20))
                            .foregroundColor(.purple)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Note")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                        
                        Text("Personal reflection")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Sync status indicator
                    if !note.isSynced {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.orange)
                            .font(.system(size: 16))
                    } else if note.syncError != nil {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(.red)
                            .font(.system(size: 16))
                    }
                    
                    Button(action: {
                        showingEditNote = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(.tealBlue)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.tealBlue.opacity(0.1))
                            )
                    }
                }
            }
            
            Text(note.content)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(nil)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .sheet(isPresented: $showingEditNote) {
            EditNoteView(note: note)
        }
    }
}

// MARK: - Add/Edit Note Views
struct AddNoteView: View {
    let date: Date
    let onSave: () -> Void

    @State private var noteContent = ""
    @Environment(\.dismiss) private var dismiss
    @StateObject private var diaryManager = DiaryManager.shared
    @State private var isExpanded = false
    @FocusState private var isTextEditorFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom header
                headerSection
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Date display card
                        dateCard
                        
                        // Text editor section
                        textEditorSection
                        
                        // Quick suggestion chips
                        quickSuggestions
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
                .background(Color(.systemGray6))
            }
            .navigationBarHidden(true)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextEditorFocused = true
                }
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Cancel")
                }
                .foregroundColor(.tealBlue)
                .font(.system(size: 16, weight: .medium))
            }
            
            Spacer()
            
            Text("New Note")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.deepPurple)
            
            Spacer()
            
            Button(action: saveNote) {
                Text("Save")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(noteContent.isEmpty ? .gray : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(noteContent.isEmpty ? Color.gray.opacity(0.2) : Color.ascendGreen)
                    )
            }
            .disabled(noteContent.isEmpty)
            .animation(.easeInOut(duration: 0.2), value: noteContent.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .background(Color.white)
    }
    
    private var dateCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Adding note for")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(date, formatter: dayFormatter)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.deepPurple)
            }
            
            Spacer()
            
            Image(systemName: "note.text")
                .font(.system(size: 32))
                .foregroundColor(.tealBlue)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var textEditorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("How was your day?")
                    .font(.headline)
                    .foregroundColor(.deepPurple)
                
                Spacer()
                
                Text("\(noteContent.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.1))
                    )
            }
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isTextEditorFocused ? Color.tealBlue : Color.gray.opacity(0.3),
                                lineWidth: isTextEditorFocused ? 2 : 1
                            )
                    )
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 0) {
                    if noteContent.isEmpty {
                        Text("Write about your climbing session, how you felt, what you learned, or anything else on your mind...")
                            .foregroundColor(.gray.opacity(0.7))
                            .font(.body)
                            .padding(.top, 16)
                            .padding(.horizontal, 16)
                            .allowsHitTesting(false)
                    }
                    
                    TextEditor(text: $noteContent)
                        .focused($isTextEditorFocused)
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(Color.clear)
                        .scrollContentBackground(.hidden)
                }
            }
            .frame(minHeight: isExpanded ? 300 : 180)
            .animation(.easeInOut(duration: 0.3), value: isExpanded)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(isExpanded ? "Collapse" : "Expand")
                        .font(.caption)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.tealBlue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var quickSuggestions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick starters")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.deepPurple)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(suggestionPrompts, id: \.self) { prompt in
                    Button(action: {
                        if noteContent.isEmpty {
                            noteContent = prompt
                        } else {
                            noteContent += "\n\n" + prompt
                        }
                        isTextEditorFocused = true
                    }) {
                        Text(prompt)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var suggestionPrompts: [String] {
        [
            "Today I climbed...",
            "I felt strong when...",
            "I struggled with...",
            "Tomorrow I want to work on...",
            "My energy level was...",
            "I learned that..."
        ]
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }
    
    private func saveNote() {
        diaryManager.addDailyNote(date: date, content: noteContent.trimmingCharacters(in: .whitespacesAndNewlines))
        onSave()
        dismiss()
    }
}

// MARK: - Enhanced Edit Note View
struct EditNoteView: View {
    let note: DailyNote
    @State private var noteContent: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var diaryManager = DiaryManager.shared
    @State private var showDeleteAlert = false
    @State private var isExpanded = false
    @FocusState private var isTextEditorFocused: Bool

    init(note: DailyNote) {
        self.note = note
        _noteContent = State(initialValue: note.content)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom header
                headerSection
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Date display card
                        dateCard
                        
                        // Text editor section
                        textEditorSection
                        
                        // Metadata section
                        metadataSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
                .background(Color(.systemGray6))
            }
            .navigationBarHidden(true)
            .alert("Delete Note", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    diaryManager.deleteDailyNote(note)
                    dismiss()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(.tealBlue)
                .font(.system(size: 16, weight: .medium))
            }
            
            Spacer()
            
            Text("Edit Note")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.deepPurple)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: { showDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                        )
                }
                
                Button(action: saveNote) {
                    Text("Save")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.ascendGreen)
                        )
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .background(Color.white)
    }
    
    private var dateCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Note from")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(note.date, formatter: dayFormatter)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.deepPurple)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if !note.isSynced {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption)
                        Text("Syncing...")
                            .font(.caption2)
                    }
                    .foregroundColor(.orange)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Saved")
                            .font(.caption2)
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var textEditorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your note")
                    .font(.headline)
                    .foregroundColor(.deepPurple)
                
                Spacer()
                
                Text("\(noteContent.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.1))
                    )
            }
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isTextEditorFocused ? Color.tealBlue : Color.gray.opacity(0.3),
                                lineWidth: isTextEditorFocused ? 2 : 1
                            )
                    )
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                TextEditor(text: $noteContent)
                    .focused($isTextEditorFocused)
                    .font(.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
            }
            .frame(minHeight: isExpanded ? 300 : 180)
            .animation(.easeInOut(duration: 0.3), value: isExpanded)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(isExpanded ? "Collapse" : "Expand")
                        .font(.caption)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.tealBlue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Note details")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.deepPurple)
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.tealBlue)
                        .frame(width: 20)
                    Text("Created")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(note.createdAt, formatter: timeFormatter)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                if let updatedAt = note.updatedAt {
                    HStack {
                        Image(systemName: "pencil")
                            .foregroundColor(.tealBlue)
                            .frame(width: 20)
                        Text("Last edited")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(updatedAt, formatter: timeFormatter)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    private func saveNote() {
        diaryManager.updateDailyNote(note, newContent: noteContent.trimmingCharacters(in: .whitespacesAndNewlines))
        dismiss()
    }
}

extension DiaryManager {
    func setupExerciseUpdateListener() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ExerciseDataUpdated"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            // Force refresh of diary data when exercise data changes
            self.objectWillChange.send()
            
            if let userInfo = notification.userInfo,
               let oldDate = userInfo["oldDate"] as? Date,
               let newDate = userInfo["newDate"] as? Date {
                print("📅 Diary: Exercise moved from \(oldDate) to \(newDate)")
            }
        }
    }
}

