//
//  AddLogEntryView.swift
//  Ascendify
//
//  Created by Ellis Barker on 15/03/2025.
//

import SwiftUI

struct AddLogEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var projectsManager = ProjectsManager.shared

    /// Now a plain server‐side ID string (already lowercased)
    let projectId: String
    
    @State private var date = Date()
    @State private var content = ""
    @State private var selectedMood: MoodRating? = nil
    @State private var errorMessage: String? = nil
    @State private var isSaving = false
    
    var body: some View {
        VStack(spacing: 0) {
            DetailHeaderView {
                dismiss()
            }
            formContent
        }
        .navigationBarHidden(true)
        .disabled(isSaving)
        .overlay(
            Group {
                if isSaving {
                    ProgressView("Saving...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 3)
                }
            }
        )
    }
    
    private var formContent: some View {
        Form {
            entrySection
            moodSection
            errorSection
            saveButtonSection
        }
        .listStyle(InsetGroupedListStyle())
    }

    @ViewBuilder
    private var entrySection: some View {
        Section(header: Text("LOG ENTRY")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)) {
            DatePicker("Date", selection: $date, displayedComponents: .date)
            ZStack(alignment: .topLeading) {
                if content.isEmpty {
                    Text("Enter your log entry...")
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                TextEditor(text: $content)
                    .frame(minHeight: 150)
                    .padding(.horizontal, -4)
            }
        }
    }
    
    private var moodSection: some View {
        Section(header: Text("HOW DID YOUR SESSION GO?")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)) {
            HStack(spacing: 10) {
                ForEach(MoodRating.allCases, id: \.self) { mood in
                    MoodSelectionButton(
                        mood: mood,
                        isSelected: selectedMood == mood,
                        action: { selectedMood = mood }
                    )
                }
            }
            .listRowInsets(EdgeInsets())
            .padding(.vertical, 5)
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let error = errorMessage {
            Section {
                Text(error)
                    .foregroundColor(.red)
            }
        }
    }

    private var saveButtonSection: some View {
        Section {
            Button(action: saveLogEntry) {
                Text("Save Log Entry")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .background(Color.ascendGreen)
            .cornerRadius(10)
            .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
            .disabled(isSaving)
        }
    }

    private func saveLogEntry() {
        errorMessage = nil
        guard !content.isEmpty else {
            errorMessage = "Please enter log content"
            return
        }
        isSaving = true
        Task { await performSave() }
    }

    @MainActor
    private func performSave() async {
        // Add the log entry (async but non-throwing)
        await projectsManager.addLogEntry(
                 to: projectId,
            date: date,
            content: content,
            mood: selectedMood
        )

        // Handle any server-side error
        if let error = projectsManager.error {
            errorMessage = error
            isSaving = false
            return
        }

        // Reload projects
        await projectsManager.loadProjects()

        // Brief pause to allow UI/server to sync
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // Update UI state and dismiss
        isSaving = false
        NotificationCenter.default.post(name: Notification.Name("LogEntryAdded"), object: nil)
        dismiss()
    }
}

// MARK: - MoodSelectionButton

extension AddLogEntryView {
    struct MoodSelectionButton: View {
        let mood: MoodRating
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Text(mood.rawValue.capitalized)
                    .font(.system(size: 16))
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? mood.color : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? mood.color : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Preview

struct AddLogEntryView_Previews: PreviewProvider {
    static var previews: some View {
        AddLogEntryView(projectId: UUID().uuidString.lowercased())
    }
}
