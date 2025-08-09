//
//  ProjectsView.swift
//  Ascendify
//
//  Created by Ellis Barker on 15/03/2025.
//

import SwiftUI

struct ProjectsView: View {
    @ObservedObject var projectsManager = ProjectsManager.shared
    @EnvironmentObject var userViewModel: UserViewModel
    
    @State private var showAddProjectSheet = false
    @State private var showAuthAlert = false
    @State private var showForceLoginAlert = false
    @State private var selectedProject: ProjectModel? = nil
    @State private var showProjectDetail = false
    
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
                    VStack(alignment: .center, spacing: 20) {
                        Spacer()
                        Text("No Projects Yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Add a climbing project to keep track of your progress")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.top)
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
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                ProjectDetailViewWrapper(project: project, isPresented: $showProjectDetail)
                    .transition(.move(edge: .trailing))
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
        .onAppear {
            print("ProjectsView appeared - checking auth status")
            
            ProjectsManager.shared.debugTokenInfo()
            ProjectsManager.shared.debugAuthTest()
            
            // Don't attempt to load projects in preview
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                Task {
                    await projectsManager.loadProjects()
                }
            }
            #else
            Task {
                await projectsManager.loadProjects()
            }
            #endif
        }
    }
    
    // Extract projects list view to avoid repetition
    private var projectsList: some View {
        List {
            ForEach(projectsManager.projects) { project in
                Button {
                    selectedProject = project
                    showProjectDetail = true
                } label: {
                    ProjectRowView(project: project)
                }
                .buttonStyle(PlainButtonStyle())
                .listRowInsets(EdgeInsets())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
            }
            .onDelete { indexSet in
                deleteProjects(at: indexSet)
            }
        }
        .listStyle(PlainListStyle())
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
                Text(project.routeName)
                    .font(.headline)
                
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
    }
}

struct ProjectsView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock UserViewModel with isSignedIn set to true
        let mockUserViewModel = UserViewModel()
        mockUserViewModel.isSignedIn = true
        
        // Create a more complete profile
        var profile = UserProfile()
        profile.email = "preview@example.com"
        profile.name = "Preview User"
        mockUserViewModel.userProfile = profile
        
        // Create mock projects for the preview
        let mockProjects = [
            ProjectModel(
                id: UUID(),
                routeName: "Test Project",
                grade: "6c",
                crag: "Test Crag",
                description: "A test project",
                routeAngle: .vertical,
                routeLength: .medium,
                holdType: .jugs,
                logEntries: [LogEntry(date: Date(), content: "Test log entry")]
            ),
            ProjectModel(
                id: UUID(),
                routeName: "Another Project",
                grade: "7a",
                crag: "Test Crag 2",
                description: "Another test project",
                routeAngle: .overhang,
                routeLength: .short,
                holdType: .crimpy
            )
        ]
        
        // Set up the preview environment
        let view = NavigationView {
            ProjectsView()
                .environmentObject(mockUserViewModel)
                .onAppear {
                    // Add mock projects directly to the manager
                    ProjectsManager.shared.projects = mockProjects
                    ProjectsManager.shared.isLoading = false
                    ProjectsManager.shared.error = nil
                }
        }
        
        return view
    }
}
