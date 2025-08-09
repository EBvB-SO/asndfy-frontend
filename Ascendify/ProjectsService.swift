//
//  ProjectsService.swift
//  Ascendify
//
//  Created by Ellis Barker on 17/03/2025.
//

import Foundation

struct ProjectsService {
    static let shared = ProjectsService()
    private init() {}
    
    // Get all projects for user
    func getProjects() async throws -> [ProjectModel] {
        // Assume you have current user email stored
        let email = UserViewModel.shared.userProfile?.email ?? ""
        return try await NetworkManager.shared.get(endpoint: "/projects/\(email)")
    }
    
    // Create new project
    func createProject(project: ProjectCreateData) async throws -> ProjectResponse {
        let email = UserViewModel.shared.userProfile?.email ?? ""
        return try await NetworkManager.shared.post(endpoint: "/projects/\(email)", body: project)
    }
    
    // Add other methods for updating, deleting projects
}

// Types needed for the API
struct ProjectCreateData: Codable {
    let route_name: String
    let grade: String
    let crag: String
    let description: String
    let route_angle: String
    let route_length: String
    let hold_type: String
}

struct ProjectResponse: Codable {
    let success: Bool
    let message: String
    let project_id: String?
}
