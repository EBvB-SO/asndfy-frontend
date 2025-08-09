//
//  ProjectDetailView.swift
//  Ascendify
//
//  Created by Ellis Barker on 15/03/2025.
//

import SwiftUI
import Foundation

struct ProjectDetailView: View {
    var project: ProjectModel
    @StateObject private var projectsManager = ProjectsManager.shared
    @State private var showAddLogSheet = false
    @Environment(\.dismiss) private var dismiss
    
    // Add state to force UI updates
    @State private var viewRefreshTrigger = UUID()
    
    // We need to get the updated project from the manager
    private var updatedProject: ProjectModel {
        if let index = projectsManager.projects.firstIndex(where: { $0.id == project.id }) {
            return projectsManager.projects[index]
        }
        return project
    }
    
    // Function to handle deleting log entries
    private func deleteLogEntries(at offsets: IndexSet) {
        let sortedEntries = updatedProject.logEntries.sorted { $0.date > $1.date }
        for offset in offsets {
            let entry = sortedEntries[offset]
            if let entryIndex = updatedProject.logEntries.firstIndex(where: { $0.id == entry.id }) {
                Task {
                    // now pass the string directly
                    await projectsManager.deleteLogEntry(from: project.id, at: entryIndex)
                }
            }
        }
    }

    
    // Method to refresh project data
    private func refreshProjectData() async {
        print("Refreshing project data for ID: \(project.id)")
        
        // First load the specific project details
        await projectsManager.safelyLoadProjectDetails(projectId: project.id.lowercased())
        
        // Then reload all projects
        await projectsManager.loadProjects()
        
        // Force UI update
        viewRefreshTrigger = UUID()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Style badges - all three categories
                VStack(spacing: 8) {
                    // Route Angle Badge
                    HStack {
                        Image(systemName: project.routeAngle.iconName)
                            .foregroundColor(.tealBlue)
                        Text(project.routeAngle.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.tealBlue)
                        
                        Spacer()
                        
                        Text("Angle")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.tealBlue.opacity(0.1))
                    )
                    
                    // Route Length Badge
                    HStack {
                        Image(systemName: project.routeLength.iconName)
                            .foregroundColor(.ascendGreen)
                        Text(project.routeLength.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.ascendGreen)
                        
                        Spacer()
                        
                        Text("Length")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.ascendGreen.opacity(0.1))
                    )
                    
                    // Hold Type Badge
                    HStack {
                        Image(systemName: project.holdType.iconName)
                            .foregroundColor(.deepPurple)
                        Text(project.holdType.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.deepPurple)
                        
                        Spacer()
                        
                        Text("Hold Type")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.deepPurple.opacity(0.1))
                    )
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                HStack {
                    Text("Grade: \(project.grade)")
                        .font(.headline)
                        .foregroundColor(.tealBlue)
                    
                    Spacer()
                    
                    Text("Crag: \(project.crag)")
                        .font(.headline)
                        .foregroundColor(.tealBlue)
                    
                    if updatedProject.isCompleted {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.ascendGreen)
                    }
                }
                .padding(.horizontal)
                
                if !project.description.isEmpty {
                    Text("Description:")
                        .font(.headline)
                        .foregroundColor(.tealBlue)
                        .padding(.horizontal)
                        .padding(.top, 5)
                    
                    Text(project.description)
                        .font(.body)
                        .padding(.horizontal)
                }
                
                // Show completion date if available
                if updatedProject.isCompleted, let completionDate = updatedProject.completionDate {
                    Text("Sent on \(dateFormatter.string(from: completionDate))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 5)
                }
                
                // Project completion buttons
                if !updatedProject.isCompleted {
                    Button(action: {
                        Task {
                            print("Attempting to mark project as sent: \(project.id)")
                            await projectsManager.toggleProjectCompletion(
                                projectId: project.id.lowercased(),  // Pass ID directly as String
                                isCompleted: true
                            )
                            // Force UI update
                            viewRefreshTrigger = UUID()
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Mark as Sent")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ascendGreen)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                } else {
                    // Similar pattern for the Undo button - reuse the pattern above
                    Button(action: {
                        Task {
                            print("Attempting to mark project as not sent: \(project.id)")
                            // Pass project.id directly as String - no UUID conversion
                            await projectsManager.toggleProjectCompletion(
                                projectId: project.id.lowercased(),
                                isCompleted: false
                            )
                            // Force UI update
                            viewRefreshTrigger = UUID()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.uturn.backward.circle.fill")
                            Text("Undo Send")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Logs section title
                Text("Progress Log")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.deepPurple)
                    .padding(.horizontal)
                
                // Debug print to verify logs
                let _ = print("ProjectDetailView: Project has \(updatedProject.logEntries.count) log entries")
                
                if updatedProject.logEntries.isEmpty {
                    Text("No log entries yet. Add your first entry!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                } else {
                    // Display logs in a list with swipe-to-delete
                    VStack(spacing: 8) {
                        ForEach(updatedProject.logEntries.sorted(by: { $0.date > $1.date })) { entry in
                            LogEntryView(entry: entry)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .refreshable {
            await refreshProjectData()
        }
        
        // Add log button
        Button {
            showAddLogSheet = true
        } label: {
            Text("Add Log Entry")
                .foregroundColor(.offWhite)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.ascendGreen)
                .cornerRadius(8)
                .padding()
        }
        .sheet(isPresented: $showAddLogSheet, onDismiss: {
            // After sheet is dismissed, reload project data
            Task {
                await refreshProjectData()
            }
        }) {
            AddLogEntryView(projectId: project.id)
            }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LogEntryAdded"))) { _ in
                    print("ProjectDetailView received LogEntryAdded notification")
                    Task {
                        await refreshProjectData()
                }
                }
                .onAppear {
                    print("ProjectDetailView appeared for project: \(project.id)")
                    
                    // ADD THIS DEBUG CALL:
                    UserViewModel.shared.debugJWTToken()
                    
                    // Initial loading
                    Task {
                        await projectsManager.safelyLoadProjectDetails(projectId: project.id.lowercased())
                    }
                }
                // Keep a stable ID for this view that updates when data changes
                .id("project-detail-\(project.id)-\(viewRefreshTrigger)")
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

// Helper view for displaying a log entry
struct LogEntryView: View {
    var entry: LogEntry
    @State private var showFullEntry = false
    
    var body: some View {
        Button(action: {
            showFullEntry = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(formattedDate)
                        .font(.headline)
                        .foregroundColor(.tealBlue)
                    
                    Spacer()
                    
                    // Show mood icon if available
                    if let mood = entry.mood {
                        Image(systemName: mood.iconName)
                            .foregroundColor(mood.color)
                    }
                }
                
                Text(entry.content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .frame(height: 100)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showFullEntry) {
            FullLogEntryView(entry: entry)
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: entry.dateObject)
    }
}

// View for displaying the full log entry in a sheet
struct FullLogEntryView: View {
    var entry: LogEntry
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(formattedDate)
                            .font(.headline)
                            .foregroundColor(.tealBlue)
                        
                        Spacer()
                        
                        // Show mood if available
                        if let mood = entry.mood {
                            HStack {
                                Image(systemName: mood.iconName)
                                Text(mood.rawValue.capitalized)
                            }
                            .foregroundColor(mood.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(mood.color.opacity(0.2))
                            )
                        }
                    }
                    .padding(.top)
                    
                    Text(entry.content)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .padding()
            }
            .navigationBarTitle("Log Entry", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: entry.dateObject)
    }
}

struct ProjectDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProjectDetailView(
                project: ProjectModel(
                    routeName: "Example Route",
                    grade: "7a+",
                    crag: "Example Crag",
                    description: "This is an example project description.",
                    logEntries: [
                        LogEntry(date: Date(), content: "First attempt. Managed to figure out the first crux."),
                        LogEntry(date: Date().addingTimeInterval(-86400), content: "Second attempt. Got higher today!")
                    ]
                )
            )
        }
    }
}
