//
//  SessionDetailView.swift
//  Ascendify
//
//  Created by Ellis Barker on 19/04/2025.
//

import SwiftUI

// MARK: - Tab Selection
enum SessionDetailTab: String, CaseIterable {
    case exercises = "Exercises"
    case notes     = "Notes"
    case history   = "History"
}

// MARK: - Session Edit Sheet
struct SessionEditSheet: View {
    let session: SessionTracking
    @State private var editedNotes: String
    @State private var editedDate: Date
    @State private var isCompleted: Bool
    @Environment(\.dismiss) private var dismiss
    
    let onSave: (String, Date, Bool) -> Void
    
    init(session: SessionTracking, onSave: @escaping (String, Date, Bool) -> Void) {
        self.session = session
        self.onSave = onSave
        _editedNotes = State(initialValue: session.notes)
        _editedDate = State(initialValue: session.completionDate ?? Date())
        _isCompleted = State(initialValue: session.isCompleted)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Session Details") {
                    HStack {
                        Text("Session:")
                        Spacer()
                        Text(session.focusName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Week:")
                        Spacer()
                        Text("Week \(session.weekNumber)")
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("Mark as Completed", isOn: $isCompleted)
                    
                    if isCompleted {
                        DatePicker(
                            "Completion Date",
                            selection: $editedDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
                
                Section("Session Notes") {
                    TextEditor(text: $editedNotes)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    onSave(editedNotes, isCompleted ? editedDate : Date(), isCompleted)
                    dismiss()
                }
                .fontWeight(.semibold)
            )
        }
    }
}

// MARK: - Exercise Edit Sheet
struct ExerciseHistoryEditSheet: View {
    let exerciseTitle: String
    let historyEntries: [ExerciseTracking]
    @ObservedObject private var trackingManager = SessionTrackingManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(historyEntries.sorted { $0.date > $1.date }, id: \.id) { entry in
                    ExerciseHistoryEditRow(
                        entry: entry,
                        onUpdate: { updatedEntry in
                            // Update the entry in the tracking manager
                            updateExerciseEntry(updatedEntry)
                        },
                        onDelete: { entryToDelete in
                            deleteExerciseEntry(entryToDelete)
                        }
                    )
                }
            }
            .navigationTitle("Edit \(exerciseTitle)")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
    
    private func updateExerciseEntry(_ updatedEntry: ExerciseTracking) {
        // Call tracking manager method to update the entry
        trackingManager.updateExerciseEntry(updatedEntry)
    }
    
    private func extractExerciseTitleFromNotes(_ notes: String) -> String {
        if let range = notes.range(of: #"\[EXERCISE:([^\]]+)\]"#, options: .regularExpression) {
            let match = String(notes[range])
            return match
                .replacingOccurrences(of: "[EXERCISE:", with: "")
                .replacingOccurrences(of: "]", with: "")
        }
        return "Unknown Exercise"
    }
    
    private func deleteExerciseEntry(_ entry: ExerciseTracking) {
        // Call tracking manager method to delete the entry
        trackingManager.deleteExerciseEntry(entry)
    }
    
    private func deleteFromServer(_ entry: ExerciseTracking) async {
        // Implementation would call the delete API endpoint
        print("Deleting exercise from server: \(entry.id)")
    }
}

struct ExerciseHistoryEditRow: View {
    @State private var entry: ExerciseTracking
    @State private var showingEditSheet = false
    
    let onUpdate: (ExerciseTracking) -> Void
    let onDelete: (ExerciseTracking) -> Void
    
    init(entry: ExerciseTracking, onUpdate: @escaping (ExerciseTracking) -> Void, onDelete: @escaping (ExerciseTracking) -> Void) {
        _entry = State(initialValue: entry)
        self.onUpdate = onUpdate
        self.onDelete = onDelete
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.date, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    let cleanedNotes = SessionTrackingManager.shared.cleanNotesForDisplay(entry.notes)
                    if !cleanedNotes.isEmpty {
                        Text(cleanedNotes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    } else {
                        Text("No notes")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .italic()
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    if entry.isSynced {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else if entry.syncError != nil {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                    
                    Button("Edit") {
                        showingEditSheet = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            ExerciseEntryEditSheet(
                entry: entry,
                onSave: { updatedEntry in
                    entry = updatedEntry
                    onUpdate(updatedEntry)
                }
            )
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", role: .destructive) {
                onDelete(entry)
            }
        }
    }
}

struct ExerciseEntryEditSheet: View {
    @State private var editedDate: Date
    @State private var editedNotes: String
    @Environment(\.dismiss) private var dismiss
    
    private let entry: ExerciseTracking
    private let onSave: (ExerciseTracking) -> Void
    
    init(entry: ExerciseTracking, onSave: @escaping (ExerciseTracking) -> Void) {
        self.entry = entry
        self.onSave = onSave
        _editedDate = State(initialValue: entry.date)
        
        // Extract the actual notes content, removing the system tags
        let cleanedNotes = SessionTrackingManager.shared.cleanNotesForDisplay(entry.notes)
        _editedNotes = State(initialValue: cleanedNotes)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Exercise Details") {
                    HStack {
                        Text("Exercise:")
                        Spacer()
                        Text(extractExerciseTitle())
                            .foregroundColor(.secondary)
                    }
                    
                    DatePicker(
                        "Date",
                        selection: $editedDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                
                Section("Notes") {
                    TextEditor(text: $editedNotes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Exercise Entry")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveChanges()
                    dismiss()
                }
                .fontWeight(.semibold)
            )
        }
    }
    
    private func extractExerciseTitle() -> String {
        // Extract title from [EXERCISE:title] format
        if let range = entry.notes.range(of: #"\[EXERCISE:([^\]]+)\]"#, options: .regularExpression) {
            let match = String(entry.notes[range])
            return match
                .replacingOccurrences(of: "[EXERCISE:", with: "")
                .replacingOccurrences(of: "]", with: "")
        }
        return "Unknown Exercise"
    }
    
    private func saveChanges() {
        // Reconstruct the notes with system tags
        let exerciseTitle = extractExerciseTitle()
        let keyMatch = entry.notes.range(of: #"\[KEY:([^\]]+)\]"#, options: .regularExpression)
        let keyTag = keyMatch != nil ? String(entry.notes[keyMatch!]) : ""

        let updatedNotes: String
        if editedNotes.isEmpty {
            updatedNotes = "[EXERCISE:\(exerciseTitle)]\(keyTag) Completed"
        } else {
            updatedNotes = "[EXERCISE:\(exerciseTitle)]\(keyTag) \(editedNotes)"
        }

        // Preserve the original ID so the backend can find the record
        let updatedEntry = ExerciseTracking(
            preservingId: entry.id,
            planId: entry.planId,
            sessionId: entry.sessionId,
            exerciseId: entry.exerciseId,
            date: editedDate,
            notes: updatedNotes
        )

        onSave(updatedEntry)
    }
}

// MARK: - Main Session Detail View (Enhanced)
struct SessionDetailView: View {
    let plan: PlanModel
    let planSession: PlanSession
    let sessionTracking: SessionTracking

    @ObservedObject private var trackingManager = SessionTrackingManager.shared
    @State private var notes: String
    @State private var isCompleted: Bool
    @State private var selectedTab: SessionDetailTab = .exercises
    @State private var isRefreshing: Bool = false
    
    // Edit states
    @State private var showingSessionEdit = false
    @State private var showingExerciseHistoryEdit = false
    @State private var selectedExerciseForEdit: String = ""

    @State private var showExerciseNote: Bool = false
    @State private var selectedExerciseId: UUID? = nil
    @State private var selectedExerciseTitle: String = ""
    @State private var exerciseNoteText: String = ""

    @State private var showingAutoComplete = false

    init(plan: PlanModel,
         planSession: PlanSession,
         sessionTracking: SessionTracking) {
        self.plan = plan
        self.planSession = planSession
        self.sessionTracking = sessionTracking
        _notes = State(initialValue: sessionTracking.notes)
        _isCompleted = State(initialValue: sessionTracking.isCompleted)
    }

    // MARK: - Exercise Model
    struct SessionExercise: Identifiable {
        let id = UUID()
        let exercise: PlanExercise
        let originalTitle: String
        let displayTitle: String

        init(exercise: PlanExercise, originalTitle: String? = nil) {
            self.exercise = exercise
            self.originalTitle = originalTitle ?? exercise.title
            self.displayTitle = exercise.title
        }
    }

    // MARK: - Static Helper Methods
    private static func cleanExerciseTitle(_ title: String) -> String {
        var cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if let range = cleaned.range(of: #"\s*\([^)]+\)"#, options: .regularExpression) {
            cleaned.removeSubrange(range)
        }
        let suffixes = [" exercise", " exercises", " drill", " drills"]
        for suffix in suffixes where cleaned.lowercased().hasSuffix(suffix) {
            cleaned = String(cleaned.dropLast(suffix.count))
        }
        return cleaned.trimmingCharacters(in: .whitespaces)
    }

    private static func inferType(from title: String) -> String {
        let l = title.lowercased()
        if l.contains("finger")   { return "fingerboard" }
        if l.contains("boulder")  { return "bouldering" }
        if l.contains("core")     { return "core" }
        if l.contains("strength") { return "strength" }
        if l.contains("power")    { return "power" }
        if l.contains("endurance"){ return "endurance" }
        if l.contains("technique"){ return "technique" }
        if l.contains("mobility") { return "mobility" }
        return "climbing"
    }

    // MARK: - Computed Properties
    private var allExercises: [SessionExercise] {
        let warms = planSession.warmUp.map { title in
            SessionExercise(exercise: PlanExercise(type: "warm-up", title: title, description: "Warm-up"))
        }
        
        let mains = planSession.mainWorkout.flatMap { ex -> [SessionExercise] in
            if ex.title.contains("+") {
                let parts = ex.title
                    .split(separator: "+")
                    .map(String.init)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                
                return parts.map { part in
                    let cleaned = Self.cleanExerciseTitle(part)
                    return SessionExercise(
                        exercise: PlanExercise(
                            type: Self.inferType(from: cleaned),
                            title: cleaned,
                            description: ex.description
                        ),
                        originalTitle: ex.title
                    )
                }
            } else {
                let cleaned = Self.cleanExerciseTitle(ex.title)
                return [SessionExercise(
                    exercise: PlanExercise(
                        type: ex.type,
                        title: cleaned,
                        description: ex.description
                    ),
                    originalTitle: ex.title
                )]
            }
        }
        
        let cools = planSession.coolDown.map { title in
            SessionExercise(exercise: PlanExercise(type: "cool-down", title: title, description: "Cool-down"))
        }
        
        return warms + mains + cools
    }

    private var mainWorkoutExercises: [SessionExercise] {
        allExercises.filter { $0.exercise.type != "warm-up" && $0.exercise.type != "cool-down" }
    }

    private func combinedHistory(for sessionEx: SessionExercise) -> [ExerciseTracking] {
        let exactTitle = sessionEx.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let entries = trackingManager.getHistoryForExerciseTitle(
            exerciseTitle: exactTitle,
            planId: sessionTracking.planId
        )
        
        return entries.sorted { $0.date > $1.date }
    }

    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                header
                Picker("", selection: $selectedTab) {
                    ForEach(SessionDetailTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                Group {
                    switch selectedTab {
                        case .exercises: exercisesList()
                        case .notes:     notesView()
                        case .history:   historyView()
                    }
                }
                .animation(.easeInOut, value: selectedTab)

                if trackingManager.networkStatus == .disconnected {
                    offlineIndicator
                }

                footer
            }
            .navigationTitle("Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Edit Session") {
                    showingSessionEdit = true
                },
                trailing: syncButton
            )
            .sheet(isPresented: $showExerciseNote) { exerciseNoteSheet }
            .sheet(isPresented: $showingSessionEdit) {
                SessionEditSheet(
                    session: sessionTracking,
                    onSave: { newNotes, newDate, completed in
                        saveSessionChanges(notes: newNotes, date: newDate, completed: completed)
                    }
                )
            }
            .sheet(isPresented: $showingExerciseHistoryEdit) {
                if !selectedExerciseForEdit.isEmpty {
                    ExerciseHistoryEditSheet(
                        exerciseTitle: selectedExerciseForEdit,
                        historyEntries: trackingManager.getHistoryForExerciseTitle(
                            exerciseTitle: selectedExerciseForEdit,
                            planId: sessionTracking.planId
                        )
                    )
                }
            }
            .refreshable { await refreshData() }
            .onAppear {
                trackingManager.ensureLocalDataAccessibility()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    trackingManager.objectWillChange.send()
                }
            }
        }
        .onReceive(SessionTrackingManager.shared.$sessionTracking) { updated in
            if let sessions = updated[sessionTracking.planId],
               let new = sessions.first(where: { $0.id == sessionTracking.id }) {
                notes = new.notes
                isCompleted = new.isCompleted
            }
        }
        .onDisappear {
            SessionTrackingManager.shared.saveAllData()
        }
    }

    // MARK: - Header View
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(sessionTracking.dayOfWeek), Week \(sessionTracking.weekNumber)")
                .font(.headline)
            Text(sessionTracking.focusName)
                .font(.title3).bold()
        }
        .padding()
    }

    // MARK: - Exercises List
    private func exercisesList() -> some View {
        List {
            Section(header: Text("WARM-UP")) {
                ForEach(allExercises.filter { $0.exercise.type == "warm-up" }) { sessionEx in
                    row(for: sessionEx)
                }
            }
            Section(header: Text("MAIN WORKOUT")) {
                ForEach(mainWorkoutExercises) { sessionEx in
                    row(for: sessionEx)
                }
            }
            Section(header: Text("COOL-DOWN")) {
                ForEach(allExercises.filter { $0.exercise.type == "cool-down" }) { sessionEx in
                    row(for: sessionEx)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }

    private func row(for sessionEx: SessionExercise) -> some View {
        let done = trackingManager.isExerciseCompletedByTitle(
            planId: sessionTracking.planId,
            sessionId: sessionTracking.id,
            exerciseTitle: sessionEx.displayTitle
        )
        
        return ExerciseRowWithDetail(
            title: sessionEx.displayTitle,
            sessionId: sessionTracking.id,
            planId: sessionTracking.planId,
            isDone: done,
            action: {
                toggleExercise(sessionEx)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.trackingManager.objectWillChange.send()
                }
            }
        )
    }

    // MARK: - Notes View (Enhanced)
    private func notesView() -> some View {
        VStack(spacing: 16) {
            TextEditor(text: $notes)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3)))
                .padding(.horizontal)
            
            Button(action: saveSessionNotes) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save Notes")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.tealBlue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            Text("Tip: Use 'Edit Session' to change completion date and status")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }

    private func saveSessionNotes() {
        trackingManager.updateSessionNotes(
            planId: sessionTracking.planId,
            sessionId: sessionTracking.id,
            notes: notes
        )
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - History View (Enhanced)
    private func historyView() -> some View {
        List {
            ForEach(mainWorkoutExercises) { sessionEx in
                Section(header: HStack {
                    Text(sessionEx.displayTitle)
                    Spacer()
                    Button("Edit History") {
                        selectedExerciseForEdit = sessionEx.displayTitle
                        showingExerciseHistoryEdit = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }) {
                    HistoryRowsView(
                        sessionEx: sessionEx,
                        combinedHistory: combinedHistory(for: sessionEx),
                        trackingManager: trackingManager
                    )
                }
            }
            
            Section {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("Exercise history is saved across all your training sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }

    // MARK: - Footer & Sync
    private var footer: some View {
        VStack {
            if showingAutoComplete {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Session Completed!")
                        .fontWeight(.semibold)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                .transition(.scale.combined(with: .opacity))
            } else if isCompleted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Session Complete")
                        .foregroundColor(.green)
                }
                .padding()
                .padding(.horizontal)
            }
        }
        .animation(.easeInOut, value: showingAutoComplete)
        .animation(.easeInOut, value: isCompleted)
        .padding(.bottom, 10)
    }

    private var syncButton: some View {
        Button { Task { await refreshData() } } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
        }
        .disabled(isRefreshing)
    }

    private var offlineIndicator: some View {
        HStack {
            Image(systemName: "wifi.slash").foregroundColor(.orange)
            Text("You're offline – changes saved locally")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(4)
        .padding(.horizontal)
    }

    private var exerciseNoteSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Notes for \(selectedExerciseTitle)")
                    .font(.headline)
                    .padding(.top)

                TextEditor(text: $exerciseNoteText)
                    .padding(4)
                    .frame(maxHeight: 200)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3)))
                    .padding(.horizontal)

                Button("Save") { saveExerciseNote() }
                    .disabled(exerciseNoteText.isEmpty)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ascendGreen)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            .navigationTitle("Exercise Note")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                showExerciseNote = false
            })
        }
    }

    // MARK: - Actions (Preserved from Original)
    private func toggleExercise(_ sessionEx: SessionExercise) {
        let exactTitle = sessionEx.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let key = trackingManager.generateExerciseKey(
            planId: sessionTracking.planId,
            sessionId: sessionTracking.id,
            title: exactTitle
        )
        
        let isCurrentlyCompleted = trackingManager.isExerciseCompletedByTitle(
            planId: sessionTracking.planId,
            sessionId: sessionTracking.id,
            exerciseTitle: exactTitle
        )
        
        if isCurrentlyCompleted {
            trackingManager.markExerciseIncompleteByTitle(
                planId: sessionTracking.planId,
                sessionId: sessionTracking.id,
                exerciseTitle: exactTitle
            )
            
            if isCompleted {
                isCompleted = false
                saveSessionSilently()
            }
        } else {
            if sessionEx.exercise.type == "warm-up" || sessionEx.exercise.type == "cool-down" {
                _ = trackingManager.recordExerciseCompletionWithKey(
                    planId: sessionTracking.planId,
                    sessionId: sessionTracking.id,
                    exerciseId: sessionEx.exercise.id,
                    exerciseTitle: exactTitle,
                    exerciseKey: key,
                    notes: ""
                )
                checkForAutoCompletion()
            } else {
                selectedExerciseTitle = exactTitle
                selectedExerciseId = sessionEx.exercise.id
                exerciseNoteText = ""
                showExerciseNote = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.trackingManager.objectWillChange.send()
        }
    }

    private func saveExerciseNote() {
        guard let exId = selectedExerciseId else { return }
        
        let exactTitle = selectedExerciseTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = trackingManager.generateExerciseKey(
            planId: sessionTracking.planId,
            sessionId: sessionTracking.id,
            title: exactTitle
        )
        
        _ = trackingManager.recordExerciseCompletionWithKey(
            planId: sessionTracking.planId,
            sessionId: sessionTracking.id,
            exerciseId: exId,
            exerciseTitle: exactTitle,
            exerciseKey: key,
            notes: exerciseNoteText
        )
        
        showExerciseNote = false
        checkForAutoCompletion()
    }
    
    private func saveSessionChanges(notes: String, date: Date, completed: Bool) {
        self.notes = notes
        self.isCompleted = completed
        
        trackingManager.markSessionCompleted(
            planId: sessionTracking.planId,
            sessionId: sessionTracking.id,
            completed: completed,
            notes: notes
        )
        
        // Update completion date if provided and different
        if completed, let currentDate = sessionTracking.completionDate, currentDate != date {
            // Update the completion date - would need to extend the tracking manager
            // For now, just update notes to include the date info
            let dateNote = "Completed on \(date.formatted(date: .abbreviated, time: .shortened))"
            let combinedNotes = notes.isEmpty ? dateNote : "\(notes)\n\n\(dateNote)"
            
            trackingManager.updateSessionNotes(
                planId: sessionTracking.planId,
                sessionId: sessionTracking.id,
                notes: combinedNotes
            )
        }
    }

    private func refreshData() async {
        isRefreshing = true
        await trackingManager.refreshSessions(for: sessionTracking.planId)
        isRefreshing = false
    }

    private var areAllExercisesComplete: Bool {
        for sessionEx in allExercises {
            let isComplete = trackingManager.isExerciseCompletedByTitle(
                planId: sessionTracking.planId,
                sessionId: sessionTracking.id,
                exerciseTitle: sessionEx.displayTitle
            )
            if !isComplete {
                return false
            }
        }
        return true
    }

    private func checkForAutoCompletion() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.areAllExercisesComplete && !self.isCompleted {
                self.isCompleted = true
                self.saveSessionSilently()
                withAnimation(.easeInOut) { self.showingAutoComplete = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeInOut) { self.showingAutoComplete = false }
                }
            } else if !self.areAllExercisesComplete && self.isCompleted {
                self.isCompleted = false
                self.saveSessionSilently()
            }
        }
    }

    private func saveSessionSilently() {
        trackingManager.markSessionCompleted(
            planId: sessionTracking.planId,
            sessionId: sessionTracking.id,
            completed: isCompleted,
            notes: notes
        )
    }
}

// MARK: - History Rows View (Unchanged from Original)
struct HistoryRowsView: View {
    let sessionEx: SessionDetailView.SessionExercise
    let combinedHistory: [ExerciseTracking]
    let trackingManager: SessionTrackingManager

    var body: some View {
        if !combinedHistory.isEmpty {
            ForEach(combinedHistory) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(DateFormatter.localizedString(
                            from: entry.date,
                            dateStyle: .medium,
                            timeStyle: .none)
                        )
                        .font(.subheadline)
                        .foregroundColor(.primary)

                        let cleanedNotes = trackingManager.cleanNotesForDisplay(entry.notes)
                        if !cleanedNotes.isEmpty {
                            Text(cleanedNotes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        } else {
                            Text("Completed - no notes")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .italic()
                        }
                    }
                    Spacer()
                    if entry.isSynced {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else if entry.syncError != nil {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
                .padding(.vertical, 4)
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("No history yet")
                    .font(.caption)
                    .italic()
                    .foregroundColor(.gray)
    #if DEBUG
                Text("Searched for: '\(sessionEx.displayTitle)' and '\(sessionEx.originalTitle)'")
                    .font(.caption2)
                    .foregroundColor(.orange)
    #endif
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Preview
#if DEBUG
struct SessionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Text("SessionDetailView Preview")
    }
}
#endif
