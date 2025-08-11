//
//  ProjectsManager.swift
//  Ascendify
//
//  Created by Ellis Barker on 15/03/2025.
//

import SwiftUI
import Foundation

func encodePath(_ raw: String) -> String {
    raw.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? raw
}

class ProjectsManager: ObservableObject {
    static let shared = ProjectsManager()
    
    private let baseURL = "http://127.0.0.1:8001" // Change to your server URL for production
    
    @Published var projects: [ProjectModel] = []
    @Published var isLoading = false
    @Published var error: String? = nil
    @Published var lastUpdated = Date()
    
    init() {
        Task {
            await loadProjects()
        }
    }
    
    @Published var simpleError: SimpleError? = nil

    private func handleError(_ error: Error, customMessage: String? = nil) {
        let errorMessage = customMessage ?? error.localizedDescription
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                simpleError = .offlineError
            default:
                simpleError = .networkError(errorMessage)
            }
        } else {
            simpleError = .genericError(errorMessage)
        }
        print("Error: \(errorMessage)")
    }
    
    func debugTokenInfo() {
        guard let url = URL(string: "\(baseURL)/projects/debug/token-info") else { return }
        var request = URLRequest(url: url)
        request.addAuthHeader()
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let data = data {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("=== TOKEN DEBUG INFO ===")
                        print("JWT Email: \(json["jwt_email"] ?? "nil")")
                        print("JWT Email Length: \(json["jwt_email_length"] ?? "nil")")
                        print("DB User Found: \(json["db_user_found"] ?? "nil")")
                        print("DB User Email: \(json["db_user_email"] ?? "nil")")
                        print("DB User Email Length: \(json["db_user_email_length"] ?? "nil")")
                        print("Emails Match: \(json["emails_match"] ?? "nil")")
                        print("========================")
                    } else if let responseString = String(data: data, encoding: .utf8) {
                        print("Token Debug Raw Response: \(responseString)")
                    }
                }
                if let error = error {
                    print("Token Debug Error: \(error)")
                }
            }
        }.resume()
    }
    
    func debugAuthTest() {
        guard let url = URL(string: "\(baseURL)/projects/debug/auth-test") else { return }
        var request = URLRequest(url: url)
        request.addAuthHeader()
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let data = data {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("=== AUTH TEST DEBUG INFO ===")
                        print("Current User Email: \(json["current_user_email"] ?? "nil")")
                        print("User Found in DB: \(json["user_found_in_db"] ?? "nil")")
                        print("User ID: \(json["user_id"] ?? "nil")")
                        print("User Projects Count: \(json["user_projects_count"] ?? "nil")")
                        print("Project IDs: \(json["project_ids"] ?? "nil")")
                        print("Message: \(json["message"] ?? "nil")")
                        print("============================")
                    } else if let responseString = String(data: data, encoding: .utf8) {
                        print("Auth Test Raw Response: \(responseString)")
                    }
                }
                if let error = error {
                    print("Auth Test Error: \(error)")
                }
            }
        }.resume()
    }



    // MARK: - API Functions

    @MainActor
    func safelyLoadProjectDetails(projectId: String) async {
        print("Safely loading project details for ID: \(projectId)")
        
        do {
            // Always force a fresh fetch from the server for project details
            let lowerProjectId = projectId.lowercased()
            let url = URL(string: "\(baseURL)/projects/detail/\(lowerProjectId)")!
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.addAuthHeader()
            
            if let token = UserViewModel.shared.accessToken {
                print("🔍 Current JWT token: \(token)")
            }
            
            print("🔍 Requesting project details with auth token: \(UserViewModel.shared.accessToken?.prefix(20) ?? "none")...")
            
            // Use authenticated request
            let (data, response) = try await URLSession.shared.authenticatedData(for: req)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                return
            }
            
            print("📥 Project detail response status: \(httpResponse.statusCode)")
            
            // Debug: Print response body for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Response body: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                if var updatedProject = try? JSONDecoder().decode(ProjectModel.self, from: data) {
                    // normalize the ID
                    updatedProject.id = updatedProject.id.lowercased()
                    // Find and update the project in our local array
                    if let index = projects.firstIndex(where: { $0.id.lowercased() == lowerProjectId }) {
                        projects[index] = updatedProject
                    } else {
                        // Add it if not found
                        projects.append(updatedProject)
                    }
                    
                    self.lastUpdated = Date() // Force UI refresh
                    print("✅ Successfully loaded project details with \(updatedProject.logs?.count ?? 0) logs")
                } else {
                    print("❌ Failed to decode project details")
                }
                
            case 401:
                print("❌ Authentication failed - token may be expired")
                // The authenticatedData method should handle token refresh automatically
                error = "Authentication failed. Please sign in again."
                
            case 403:
                print("❌ Forbidden - user doesn't have access to this project")
                error = "You don't have permission to view this project."
                
            case 404:
                print("❌ Project not found")
                error = "Project not found."
                
            default:
                print("❌ Unexpected status code: \(httpResponse.statusCode)")
                error = "Server error: \(httpResponse.statusCode)"
            }
            
        } catch {
            print("❌ Network error fetching project details: \(error)")
            if error.localizedDescription.contains("401") || error.localizedDescription.contains("authentication") {
                self.error = "Authentication failed. Please sign in again."
            } else {
                self.error = "Failed to load project details: \(error.localizedDescription)"
            }
        }
    }
    
    @MainActor
    func loadProjects() async {
        // If we're already loading, don't start another load
        if isLoading {
            print("ProjectsManager.loadProjects: Already loading, skipping")
            return
        }

        isLoading = true
        error = nil

        // Add debug log to help diagnose
        print("ProjectsManager.loadProjects: Starting fresh load of projects")

        // Get current user email - add more detailed error
        guard UserViewModel.shared.isSignedIn else {
            isLoading = false
            error = "User not logged in (isSignedIn=false)"
            return
        }

        guard let email = UserViewModel.shared.userProfile?.email, !email.isEmpty else {
            isLoading = false
            error = "User not logged in (no email found)"
            return
        }

        do {
            // 1. Build endpoint & call the shared NetworkManager
            let safeEmail = encodePath(email)
            let newProjects: [ProjectModel] =
                try await NetworkManager.shared.getList(endpoint: "/projects/\(safeEmail)")

            // 2. Debug logging
            print("ProjectsManager.loadProjects: Loaded \(newProjects.count) projects")
            for project in newProjects {
                let logCount = project.logs?.count ?? 0
                print("ProjectsManager.loadProjects: Project \(project.route_name) has \(logCount) logs")
            }

            // 3. Normalise IDs and publish
            self.projects = newProjects.map { proj in
                var p = proj
                p.id = proj.id.lowercased()
                return p
            }
            self.lastUpdated = Date()

            // 4. Cache the *array* (not the envelope) for offline use
            let cacheKey = "cached_projects_\(email.lowercased())"
            
            let cache = try JSONEncoder().encode(self.projects)
            UserDefaults.standard.set(cache, forKey: cacheKey)

        } catch NetworkError.notFound {
            // 404 – user simply has no projects
            self.projects = []
            self.lastUpdated = Date()
            print("ProjectsManager.loadProjects: No projects found (404)")

        } catch {
            // Any other failure
            handleError(error)
            self.error = "Failed to load projects: \(error.localizedDescription)"
            print("ProjectsManager.loadProjects ERROR: \(error)")

            // Try cache fallback
            let cacheKey = "cached_projects_\(email.lowercased())"
            
            if let cachedData = UserDefaults.standard.data(forKey: cacheKey),
               let cached = try? JSONDecoder().decode([ProjectModel].self, from: cachedData) {
                self.projects = cached
                self.lastUpdated = Date()
                self.error = "Showing cached projects. \(error.localizedDescription)"
                print("ProjectsManager.loadProjects: Loaded \(cached.count) projects from cache")
            }
        }
        isLoading = false
    }

    
    @MainActor
    func addProject(
        routeName: String,
        grade: String,
        crag: String,
        description: String,
        routeAngle: RouteAngle,
        routeLength: RouteLength,
        holdType: HoldType
    ) async {
        print("ProjectsManager: Starting to add Project")

        isLoading = true
        error = nil

        // Get current user email
        guard let email = UserViewModel.shared.userProfile?.email else {
            isLoading = false
            error = "User not logged in"
            print("ProjectsManager: No user email found")
            return
        }

        print("ProjectsManager: Using email \(email)")

        // Create project data
        let projectData = ProjectCreateRequest(
            route_name: routeName,
            grade: grade,
            crag: crag,
            description: description,
            route_angle: routeAngle.rawValue.lowercased(),
            route_length: routeLength.rawValue.lowercased(),
            hold_type: holdType.rawValue.lowercased()
        )

        do {
            let safeEmail = email.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? email
            let url = URL(string: "\(baseURL)/projects/\(safeEmail)")!
            print("ProjectsManager: Sending request to \(url)")

            // Build request and attach headers
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addAuthHeader()      // ← injects your Bearer token

            let jsonData = try JSONEncoder().encode(projectData)
            request.httpBody = jsonData
            print("ProjectsManager: Request body: \(String(data: jsonData, encoding: .utf8) ?? "")")

            // Use authenticated request
            let (data, response) = try await URLSession.shared.authenticatedData(for: request)
            print("ProjectsManager: Received response: \(response)")

            if let responseString = String(data: data, encoding: .utf8) {
                print("ProjectsManager: Response data: \(responseString)")
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            if httpResponse.statusCode == 200 {
                print("ProjectsManager: Project created successfully")
                // Reload projects to get the new one
                await loadProjects()
            } else {
                // Try to decode an error message
                if let errorResp = try? JSONDecoder().decode([String: String].self, from: data),
                   let detail = errorResp["detail"] {
                    throw NetworkError.serverError(detail)
                } else {
                    throw NetworkError.serverError("Server returned \(httpResponse.statusCode)")
                }
            }

        } catch {
            print("ProjectsManager: Error creating project: \(error)")
            self.error = "Failed to add project: \(error.localizedDescription)"
        }

        isLoading = false
    }

    
    @MainActor
    func deleteProject(at index: Int) async {
        guard index >= 0 && index < projects.count else { return }
        
        isLoading = true
        error = nil
        
        let projectId = projects[index].id.lowercased()
        guard let email = UserViewModel.shared.userProfile?.email else {
            isLoading = false; error = "No user email"
            return
        }
        
        do {
            let url = URL(string: "\(baseURL)/projects/\(email)/\(projectId)")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.addAuthHeader()
            
            // Use authenticated request
            let (data, response) = try await URLSession.shared.authenticatedData(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                // Remove from local array
                projects.remove(at: index)
            } else {
                // Try to decode error message
                if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                   let detail = errorResponse["detail"] {
                    throw NetworkError.serverError(detail)
                } else {
                    throw NetworkError.serverError("Server returned \(httpResponse.statusCode)")
                }
            }
        } catch {
            self.error = "Failed to delete project: \(error.localizedDescription)"
        }
        
        isLoading = false
    }

    struct LogEntryRequest: Encodable {
            let date: String
            let content: String
            let mood: String?
        }

        @MainActor
        func addLogEntry(to projectId: String, date: Date, content: String, mood: MoodRating?) async {
            isLoading = true
            error = nil

            let lowercaseProjectId = projectId.lowercased()
            print("Adding log entry to project: \(lowercaseProjectId)")

            guard let email = UserViewModel.shared.userProfile?.email else {
                print("ProjectsManager: Missing user email for log submission")
                return
            }

            let dateStr = ISO8601DateFormatter().string(from: date)
            
            let logEntry = LogEntryRequest(
                date: dateStr,
                content: content,
                mood: mood?.rawValue
            )

            do {
                let url = URL(string: "\(baseURL)/projects/\(email)/\(lowercaseProjectId)/logs")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addAuthHeader()
                let jsonData = try JSONEncoder().encode(logEntry)
                request.httpBody = jsonData

                print("ProjectsManager: Sending log entry request to \(url)")
                print("ProjectsManager: Request body: \(String(data: jsonData, encoding: .utf8) ?? "Could not read body")")

                // Use authenticated request
                let (data, response) = try await URLSession.shared.authenticatedData(for: request)
                print("ProjectsManager: Add log response: \(response)")

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }

                if httpResponse.statusCode == 200 {
                    print("ProjectsManager: Log entry added successfully!")
                    await safelyLoadProjectDetails(projectId: projectId)
                    NotificationCenter.default.post(name: NSNotification.Name("LogEntryAdded"), object: nil)
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await loadProjects()
                } else {
                    if let responseText = String(data: data, encoding: .utf8) {
                        print("ProjectsManager: Error response: \(responseText)")
                    }
                    throw NetworkError.serverError("Server returned \(httpResponse.statusCode)")
                }
            } catch {
                print("ProjectsManager: Error adding log entry: \(error)")
                self.error = "Failed to add log entry: \(error.localizedDescription)"
            }

            isLoading = false
        }
    
    @MainActor
    func deleteLogEntry(from projectId: String, at logIndex: Int) async {
        // projectId is already the lowercased string
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectId }),
              logIndex >= 0,
              logIndex < projects[projectIndex].logEntries.count
        else { return }

        isLoading = true
        error = nil

        let logId = projects[projectIndex].logEntries[logIndex].id.lowercased()
        let url = URL(string: "\(baseURL)/projects/logs/\(logId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addAuthHeader()

        do {
            let (data, response) = try await URLSession.shared.authenticatedData(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            if http.statusCode == 200 {
                await loadProjects()
            } else {
                if let err = try? JSONDecoder().decode([String:String].self, from: data),
                   let detail = err["detail"] {
                    throw NetworkError.serverError(detail)
                }
                throw NetworkError.serverError("Server returned \(http.statusCode)")
            }
        } catch {
            self.error = "Failed to delete log entry: \(error.localizedDescription)"
        }
        isLoading = false
    }

    
    @MainActor
    func toggleProjectCompletion(projectId: String, isCompleted: Bool) async {
        isLoading = true
        error = nil
        
        print("ProjectsManager: Toggling project \(projectId) to \(isCompleted ? "completed" : "not completed")")
        
        do {
            let id = projectId.lowercased()
            guard let email = UserViewModel.shared.userProfile?.email else { return }
            let url = URL(string: "\(baseURL)/projects/\(email)/\(id)")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addAuthHeader()
            // Create update data
            let updateData: [String: Any] = [
                "is_completed": isCompleted
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: updateData)
            request.httpBody = jsonData
            
            print("ProjectsManager: Sending toggle request to \(url)")
            
            // Use authenticated request
            let (data, response) = try await URLSession.shared.authenticatedData(for: request)
            
            print("ProjectsManager: Toggle response: \(response)")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                print("ProjectsManager: Project completion toggled successfully!")
                
                // Create a new project with updated values instead of modifying properties directly
                let normalizedId = projectId.lowercased()
                if let index = projects.firstIndex(where: { $0.id.lowercased() == normalizedId }) {
                    let currentProject = projects[index]

                    // Create a new project with updated values
                    var updatedProject = currentProject
                    updatedProject.is_completed = isCompleted
                    updatedProject.completion_date = isCompleted
                        ? ISO8601DateFormatter().string(from: Date())
                        : nil
                    projects[index] = updatedProject
                }
                
                // Reload projects to ensure everything is in sync
                await loadProjects()
            } else {
                if let responseText = String(data: data, encoding: .utf8) {
                    print("ProjectsManager: Error response: \(responseText)")
                }
                throw NetworkError.serverError("Server returned \(httpResponse.statusCode)")
            }
        } catch {
            print("ProjectsManager: Error toggling project: \(error)")
            self.error = "Failed to update project: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Statistics functions
    
    var totalProjects: Int {
        projects.count
    }
    
    var completedProjects: Int {
        projects.filter { $0.isCompleted }.count
    }
    
    var totalLogEntries: Int {
        projects.reduce(0) { $0 + $1.logEntries.count }
    }
    
    // MARK: - Style Badge functions
    
    // Get completed projects for a specific route angle
    func completedProjectsForAngle(_ angle: RouteAngle) -> Int {
        projects.filter { $0.isCompleted && $0.routeAngle == angle }.count
    }
    
    // Get completed projects for a specific route length
    func completedProjectsForLength(_ length: RouteLength) -> Int {
        projects.filter { $0.isCompleted && $0.routeLength == length }.count
    }
    
    // Get completed projects for a specific hold type
    func completedProjectsForHoldType(_ holdType: HoldType) -> Int {
        projects.filter { $0.isCompleted && $0.holdType == holdType }.count
    }
    
    // Check if user has earned angle specialist badge (3+ projects of same angle)
    func hasEarnedAngleSpecialistBadge() -> Bool {
        for angle in RouteAngle.allCases {
            if completedProjectsForAngle(angle) >= 3 {
                return true
            }
        }
        return false
    }
    
    // Check if user has earned length specialist badge (3+ projects of same length)
    func hasEarnedLengthSpecialistBadge() -> Bool {
        for length in RouteLength.allCases {
            if completedProjectsForLength(length) >= 3 {
                return true
            }
        }
        return false
    }
    
    // Check if user has earned hold type specialist badge (3+ projects of same hold type)
    func hasEarnedHoldTypeSpecialistBadge() -> Bool {
        for holdType in HoldType.allCases {
            if completedProjectsForHoldType(holdType) >= 3 {
                return true
            }
        }
        return false
    }
    
    // Get the angle with the most completed projects (for specialist badge details)
    func specialistAngle() -> RouteAngle? {
        var mostCompletedAngle: RouteAngle? = nil
        var maxCount = 0
        
        for angle in RouteAngle.allCases {
            let count = completedProjectsForAngle(angle)
            if count >= 3 && count > maxCount {
                maxCount = count
                mostCompletedAngle = angle
            }
        }
        
        return mostCompletedAngle
    }
    
    // Get the length with the most completed projects (for specialist badge details)
    func specialistLength() -> RouteLength? {
        var mostCompletedLength: RouteLength? = nil
        var maxCount = 0
        
        for length in RouteLength.allCases {
            let count = completedProjectsForLength(length)
            if count >= 3 && count > maxCount {
                maxCount = count
                mostCompletedLength = length
            }
        }
        
        return mostCompletedLength
    }
    
    // Get the hold type with the most completed projects (for specialist badge details)
    func specialistHoldType() -> HoldType? {
        var mostCompletedHoldType: HoldType? = nil
        var maxCount = 0
        
        for holdType in HoldType.allCases {
            let count = completedProjectsForHoldType(holdType)
            if count >= 3 && count > maxCount {
                maxCount = count
                mostCompletedHoldType = holdType
            }
        }
        
        return mostCompletedHoldType
    }
}
