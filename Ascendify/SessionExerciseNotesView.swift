//
//  SessionExerciseNotesView.swift
//  Ascendify
//
//  Created by Ellis Barker on 10/08/2025.
//

import SwiftUI

/// Displays all exercise notes for a single training session.
struct SessionExerciseNotesView: View {
    /// The training session for which to display exercise notes.
    let session: SessionTracking
    /// The plan identifier to use when looking up exercise history.
    let planId: String

    /// Access to the shared tracking manager which stores exercise history.
    @ObservedObject private var trackingManager = SessionTrackingManager.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // MARK: - Custom header
                VStack(spacing: 6) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 36))
                        .foregroundColor(.accentColor)

                    Text(session.focusName.isEmpty ? "Session Notes" : session.focusName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2) // Allow two lines
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)

                    // Date at top (all exercises share the same date)
                    if let sessionDate = trackingManager.exerciseHistory[planId]?
                        .first(where: { $0.sessionId == session.id })?.date {
                        Text(sessionDate, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Divider()
                        .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(UIColor.systemBackground),
                            Color(UIColor.secondarySystemBackground)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // MARK: - Exercise list
                List {
                    let entries = trackingManager.exerciseHistory[planId]?
                        .filter { $0.sessionId == session.id } ?? []

                    if entries.isEmpty {
                        Text("No exercise notes recorded for this session.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(entries) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(extractExerciseTitle(from: entry.notes))
                                    .font(.headline)
                                let cleaned = trackingManager.cleanNotesForDisplay(entry.notes)
                                if !cleaned.isEmpty {
                                    Text(cleaned)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
    }

    /// Extracts the user visible exercise title from the tagged notes string.
    private func extractExerciseTitle(from notes: String) -> String {
        if let range = notes.range(of: #"\[EXERCISE:([^\]]+)\]"#, options: .regularExpression) {
            let match = String(notes[range])
            return match
                .replacingOccurrences(of: "[EXERCISE:", with: "")
                .replacingOccurrences(of: "]", with: "")
        }
        return "Exercise"
    }
}
