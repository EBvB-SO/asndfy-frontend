//
//  ProjectsView.swift
//  Ascendify
//
//  Created by Ellis Barker on 15/03/2025.
//

import SwiftUI
import UIKit

struct ProjectsView: View {
    @ObservedObject var projectsManager = ProjectsManager.shared
    @EnvironmentObject var userViewModel: UserViewModel
    
    @State private var showAddProjectSheet = false
    @State private var showAuthAlert = false
    @State private var showForceLoginAlert = false
    @State private var selectedProject: ProjectModel? = nil
    @State private var showProjectDetail = false
    @State private var projectIndicesToDelete: IndexSet? = nil
    @State private var showProjectDeleteAlert = false
    
    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                HeaderView()
                
                if projectsManager.isLoading {
                    ProgressView("Loading projects...")
                        .padding()
                } else if let error = projectsManager.error {
                    // Check if we're in preview
                    #if DEBUG
                    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                        // In preview, show mock projects
                        projectsList
                    } else {
                        // In real app, show error
                        VStack {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                                .padding()
                            
                            Button("Retry") {
                                Task {
                                    await projectsManager.loadProjects()
                                }
                            }
                            .padding()
                            
                            if !userViewModel.isSignedIn || userViewModel.userProfile?.email == nil {
                                Button("Force Authentication") {
                                    showForceLoginAlert = true
                                }
                                .padding()
                            }
                        }
                    }
                    #else
                    // In release build, show error
                    VStack {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding()
                        
                        Button("Retry") {
                            Task {
                                await projectsManager.loadProjects()
                            }
                        }
                        .padding()
                        
                        if !userViewModel.isSignedIn || userViewModel.userProfile?.email == nil {
                            Button("Force Authentication") {
                                showForceLoginAlert = true
                            }
                            .padding()
                        }
                    }
                    #endif
                } else if projectsManager.projects.isEmpty {
                    emptyStateView
                } else {
                    projectsList
                }
                
                Button {
                    // Check if user is signed in before showing add project sheet
                    if userViewModel.isSignedIn, let email = userViewModel.userProfile?.email, !email.isEmpty {
                        showAddProjectSheet = true
                    } else {
                        showAuthAlert = true
                    }
                } label: {
                    Text("Add New Project")
                        .foregroundColor(.offWhite)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.ascendGreen)
                        .cornerRadius(8)
                        .padding()
                }
            }
            .navigationBarHidden(true)
            
            // Conditionally show project detail as an overlay
            if showProjectDetail, let project = selectedProject {
                // Background dim — slower on entry, faster on exit
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(
                        .asymmetric(
                            insertion: .opacity.animation(.easeIn(duration: 0.30)),
                            removal:  .opacity.animation(.easeOut(duration: 0.20))
                        )
                    )

                // Panel — slower on entry, snappier on exit
                ProjectDetailViewWrapper(project: project, isPresented: $showProjectDetail)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).animation(.easeInOut(duration: 0.35)),
                            removal:  .move(edge: .trailing).animation(.easeInOut(duration: 0.25))
                        )
                    )
            }
            
            // Add the error banner on top of everything else, if there's an error
            if let error = projectsManager.simpleError {
                VStack {
                    ErrorBannerView(message: error.message) {
                        // Dismiss the error
                        projectsManager.simpleError = nil
                    }
                    .transition(.move(edge: .top))
                    
                    Spacer() // Push the banner to the top
                }
                .zIndex(999) // Ensure it's above other content
            }
        }
        .animation(.easeInOut, value: projectsManager.simpleError != nil)
        .animation(.easeInOut, value: showProjectDetail)
        .sheet(isPresented: $showAddProjectSheet) {
            if let email = userViewModel.userProfile?.email {
                AddProjectView(userEmail: email)
            }
        }
        .alert("Sign In Required", isPresented: $showAuthAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You need to be signed in to add projects.")
        }
        .alert("Authentication Issue", isPresented: $showForceLoginAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Try Again") {
                if let email = userViewModel.userProfile?.email {
                    print("Force refreshing user profile for: \(email)")
                    userViewModel.fetchUserProfile(email: email) { success in
                        print("Force profile refresh result: \(success)")
                        Task {
                            await projectsManager.loadProjects()
                        }
                    }
                }
            }
        } message: {
            Text("There seems to be an issue with your authentication. Would you like to try refreshing your login state?")
        }
        .task {
            print("ProjectsView task – loading projects & checking auth")
            ProjectsManager.shared.debugTokenInfo()
            ProjectsManager.shared.debugAuthTest()
            await projectsManager.loadProjects()
        }
        .alert("Delete Project?", isPresented: $showProjectDeleteAlert) {
            Button("Delete", role: .destructive) {
                // Haptic feedback
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                guard let indexSet = projectIndicesToDelete else { return }

                // Capture the IDs we intend to delete (for safely closing the detail view)
                let idsToDelete: [String] = indexSet.compactMap { idx in
                    projectsManager.projects.indices.contains(idx) ? projectsManager.projects[idx].id : nil
                }

                Task {
                    // Delete in descending index order to avoid reindexing issues
                    for index in indexSet.sorted(by: >) {
                        await projectsManager.deleteProject(at: index)
                    }

                    // If the currently shown project was deleted, close the overlay with animation
                    if let selected = selectedProject, idsToDelete.contains(selected.id) {
                        await MainActor.run {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showProjectDetail = false
                                selectedProject = nil
                            }
                        }
                    }

                    // Tidy up the stored indices
                    await MainActor.run {
                        projectIndicesToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                // Clean up in case user cancels
                projectIndicesToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this project? All its logs will be removed.")
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(alignment: .center, spacing: 20) {
            Spacer()
            
            Image(systemName: "flag.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
                .padding(.bottom, 10)
            
            Text("No Projects Yet")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Add a climbing project to keep track of your progress")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding(.top)
    }
    
    // Extract projects list view to avoid repetition
    private var projectsList: some View {
        List {
            ForEach(projectsManager.projects) { project in
                Button {
                    // Light tap haptic when opening details
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()

                    withAnimation(.easeInOut(duration: 0.35)) {
                        selectedProject = project
                        showProjectDetail = true
                    }
                } label: {
                    ProjectRowView(project: project)
                }
                .buttonStyle(PlainButtonStyle())
                .listRowInsets(EdgeInsets())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
            }
            .onDelete { indexSet in
                projectIndicesToDelete = indexSet
                showProjectDeleteAlert = true
            }
        }
        .listStyle(PlainListStyle())
        .disabled(showProjectDetail)
    }
    
    // Function to handle swipe-to-delete action
    func deleteProjects(at offsets: IndexSet) {
        Task {
            for index in offsets {
                // Pass the project index to deleteProject
                await projectsManager.deleteProject(at: index)
            }
        }
    }
}

struct ProjectDetailViewWrapper: View {
    var project: ProjectModel
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header with back button and project name
                DetailHeaderView {
                    isPresented = false
                }
                
                // Project detail content (without its own header)
                ProjectDetailView(project: project)
            }
        }
        .transition(.move(edge: .trailing))
    }
}

struct ProjectRowView: View {
    let project: ProjectModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // Route name with better visibility and debugging
                Text(project.routeName.isEmpty ? "Unnamed Route" : project.routeName)
                    .font(.headline)
                    .foregroundColor(.primary) // Ensure it's visible in all modes
                    .lineLimit(1)
                
                Spacer()
                
                // Show completion badge if sent
                if project.isCompleted {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.ascendGreen)
                }
                
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            
            // Show grade and crag
            HStack {
                Text("Grade: \(project.grade) • Crag: \(project.crag)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Style tags row
            HStack(spacing: 6) {
                // Angle Tag
                HStack(spacing: 4) {
                    Image(systemName: project.routeAngle.iconName)
                        .font(.caption2)
                        .foregroundColor(.tealBlue)
                    Text(project.routeAngle.rawValue)
                        .font(.caption2)
                        .foregroundColor(.tealBlue)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.tealBlue.opacity(0.1))
                )
                
                // Length Tag
                HStack(spacing: 4) {
                    Image(systemName: project.routeLength.iconName)
                        .font(.caption2)
                        .foregroundColor(.ascendGreen)
                    Text(project.routeLength.rawValue)
                        .font(.caption2)
                        .foregroundColor(.ascendGreen)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.ascendGreen.opacity(0.1))
                )
                
                // Hold Type Tag
                HStack(spacing: 4) {
                    Image(systemName: project.holdType.iconName)
                        .font(.caption2)
                        .foregroundColor(.deepPurple)
                    Text(project.holdType.rawValue)
                        .font(.caption2)
                        .foregroundColor(.deepPurple)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.deepPurple.opacity(0.1))
                )
                
                Spacer()
                
                // Show logs count
                Text("\(project.logEntries.count) log entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .contentShape(Rectangle()) // Make the entire cell tappable
        .onAppear {
            // Debug print to verify route name data
            print("📝 ProjectRow - Route: '\(project.routeName)', Grade: '\(project.grade)', Crag: '\(project.crag)'")
            if project.routeName.isEmpty {
                print("⚠️ Warning: Empty route name for project ID: \(project.id)")
            }
        }
    }
}
