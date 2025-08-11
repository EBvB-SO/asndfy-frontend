//
//  EditLogEntryView.swift
//  Ascendify
//
//  Created by Ellis Barker on 11/08/2025.
//

import SwiftUI
import UIKit

struct EditLogEntryView: View {
    let projectId: String
    let logEntry: LogEntry

    @State private var entryDate: Date
    @State private var entryContent: String
    @State private var selectedMood: MoodRating?

    @StateObject private var projectsManager = ProjectsManager.shared
    @Environment(\.dismiss) private var dismiss

    // UX state
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    init(projectId: String, logEntry: LogEntry) {
        self.projectId = projectId
        self.logEntry = logEntry
        _entryDate = State(initialValue: logEntry.dateObject)
        _entryContent = State(initialValue: logEntry.content)
        _selectedMood = State(initialValue: logEntry.mood)
    }

    var body: some View {
        NavigationView {
            Form {
                DatePicker("Date", selection: $entryDate, displayedComponents: .date)

                Section(header: Text("Notes")) {
                    TextEditor(text: $entryContent)
                        .frame(minHeight: 140)
                        .disabled(isSaving)
                        .accessibilityLabel("Log notes")
                }

                Section(header: Text("Mood")) {
                    Picker("Mood", selection: $selectedMood) {
                        Text("None").tag(MoodRating?.none)
                        ForEach(MoodRating.allCases, id: \.self) { mood in
                            Text(mood.rawValue.capitalized).tag(MoodRating?.some(mood))
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .disabled(isSaving)
                }
            }
            .navigationBarTitle("Edit Log", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .bold()
                        }
                    }
                    .disabled(isSaving || entryContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Couldn't save log", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Actions
    private func save() async {
        guard !isSaving else { return }
        isSaving = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        await projectsManager.updateLogEntry(
            for: projectId,
            logId: logEntry.id,
            newDate: entryDate,
            newContent: entryContent,
            newMood: selectedMood
        )

        // ProjectsManager handles the network call internally; check its error surface.
        if let err = projectsManager.error, !err.isEmpty {
            errorMessage = err
            showError = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            isSaving = false
            return
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        isSaving = false
        dismiss()
    }
}
