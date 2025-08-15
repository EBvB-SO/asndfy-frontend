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
    
    // Get all projects for the current user
    func getProjects() async throws -> [ProjectModel] {
        let email: String = await MainActor.run {
            UserViewModel.shared.userProfile?.email ?? ""
        }
        return try await NetworkManager.shared.getList(endpoint: "/projects/\(email)")
    }
    
    // Create a new project
    func createProject(project: ProjectCreateData) async throws -> ProjectResponse {
        let email: String = await MainActor.run {
            UserViewModel.shared.userProfile?.email ?? ""
        }
        return try await NetworkManager.shared.post(endpoint: "/projects/\(email)", body: project)
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
}
