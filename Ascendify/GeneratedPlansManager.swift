//
//  GeneratedPlansManager.swift
//  Ascendify
//
//  Created by Ellis Barker on 08/02/2025.
//

import SwiftUI

class GeneratedPlansManager: ObservableObject {
    static let shared = GeneratedPlansManager()
    
    private let baseURL = "http://127.0.0.1:8001"
    
    // UserDefaults key for storing plans
    private let plansStorageKey = "ascendify_saved_plans"
    
    // We store multiple purchased plans
    @Published var plans: [PlanWrapper] = []
    
    // Loading and error states
    @Published var isLoading = false
    @Published var error: String? = nil
    
    // Initialize with plans from storage
    init() {
        loadPlans()
    }
    
    /// Saves a newly purchased plan
    func savePlan(routeName: String, grade: String, plan: PlanModel) {
        // Wrap route info + plan
        let newPlan = PlanWrapper(routeName: routeName, grade: grade, plan: plan)
        plans.append(newPlan)
        
        // Persist to storage
        savePlansToStorage()
    }
    
    /// Delete a plan
    func deletePlan(at index: Int) {
        guard index >= 0 && index < plans.count else { return }
        
        plans.remove(at: index)
        savePlansToStorage()
    }
    
    /// Save plans to UserDefaults
    private func savePlansToStorage() {
        do {
            let data = try JSONEncoder().encode(plans)
            UserDefaults.standard.set(data, forKey: plansStorageKey)
            print("Successfully saved \(plans.count) plans to storage")
        } catch {
            print("Error saving plans to storage: \(error.localizedDescription)")
        }
    }
    
    /// Load plans from UserDefaults
    private func loadPlans() {
        guard let data = UserDefaults.standard.data(forKey: plansStorageKey) else {
            print("No saved plans found in storage")
            return
        }
        
        do {
            plans = try JSONDecoder().decode([PlanWrapper].self, from: data)
            print("Successfully loaded \(plans.count) plans from storage")
        } catch {
            print("Error loading plans from storage: \(error.localizedDescription)")
        }
    }
    
    func clearPlans() {
        plans = []
        UserDefaults.standard.removeObject(forKey: plansStorageKey)
    }
    
    /// Fetch plans from server with proper authentication and token refresh
    func fetchPlansFromServer(email: String) {
        Task {
            await fetchPlansFromServerAsync(email: email)
        }
    }
    
    /// Async version of fetchPlansFromServer with proper error handling
    @MainActor
    private func fetchPlansFromServerAsync(email: String) async {
        isLoading = true
        error = nil
        
        do {
            let url = URL(string: "\(baseURL)/training_plans/\(email)")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addAuthHeader()
            
            // Use authenticated request that handles token refresh
            let (data, response) = try await URLSession.shared.authenticatedData(for: request)
            
            // Check response status
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "GeneratedPlansManager",
                             code: 0,
                             userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }
            
            switch httpResponse.statusCode {
            case 200:
                // Decode the server response
                let serverPlans = try JSONDecoder().decode([ServerPlanModel].self, from: data)
                
                // Convert server plans to PlanWrappers
                self.plans = serverPlans.map { serverPlan in
                    let planModel = PlanModel(
                        routeOverview: serverPlan.route_overview,
                        trainingOverview: serverPlan.training_overview,
                        weeks: serverPlan.phases
                    )
                    return PlanWrapper(
                        routeName: serverPlan.route_name,
                        grade: serverPlan.grade,
                        plan: planModel
                    )
                }
                
                // Save to local storage
                savePlansToStorage()
                
                print("Successfully fetched \(self.plans.count) plans from server")
                
            case 404:
                // No plans found for user
                self.plans = []
                savePlansToStorage()
                print("No plans found for user")
                
            default:
                // Try to extract error message from response
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let detail = errorData["detail"] {
                    throw NSError(domain: "GeneratedPlansManager",
                                 code: httpResponse.statusCode,
                                 userInfo: [NSLocalizedDescriptionKey: detail])
                } else {
                    throw NSError(domain: "GeneratedPlansManager",
                                 code: httpResponse.statusCode,
                                 userInfo: [NSLocalizedDescriptionKey: "Server error: \(httpResponse.statusCode)"])
                }
            }
            
        } catch let error as NSError {
            // Handle specific errors
            if error.domain == NSURLErrorDomain && error.code == URLError.userAuthenticationRequired.rawValue {
                // Authentication failed completely (even after refresh attempt)
                self.error = "Authentication required. Please sign in again."
                // The UserViewModel should have already signed out the user
            } else {
                self.error = "Error fetching plans: \(error.localizedDescription)"
            }
            print("Error fetching plans: \(error)")
            
            // Keep existing local plans if we have them
            if plans.isEmpty {
                loadPlans() // Try to load from storage
            }
            
        } catch {
            // Generic error handling
            self.error = "Error fetching plans: \(error.localizedDescription)"
            print("Error fetching plans: \(error)")
        }
        
        isLoading = false
    }
    
    /// Sync plans with server - can be called manually or on app launch
    func syncPlansWithServer() async {
        guard let email = UserViewModel.shared.userProfile?.email else {
            print("No user email found, skipping plan sync")
            return
        }
        
        await fetchPlansFromServerAsync(email: email)
    }
    
    /// Delete a plan from the server
    func deletePlanFromServer(planId: String) async throws {
        guard let email = UserViewModel.shared.userProfile?.email else {
            throw NSError(domain: "GeneratedPlansManager",
                         code: 0,
                         userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        let url = URL(string: "\(baseURL)/training_plans/\(email)/\(planId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addAuthHeader()
        
        let (_, response) = try await URLSession.shared.authenticatedData(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "GeneratedPlansManager",
                         code: 0,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode != 200 && httpResponse.statusCode != 204 {
            throw NSError(domain: "GeneratedPlansManager",
                         code: httpResponse.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to delete plan"])
        }
    }
    
    struct ServerSaveRequest: Encodable {
        let route_name: String
        let grade: String
        let route_overview: String?
        let training_overview: String?
        let phases: [Phase]

        struct Phase: Encodable {
            let phase_name: String
            let description: String
            let phase_order: Int
            let sessions: [Session]

            struct Session: Encodable {
                let day: String
                let focus: String
                let details: String
                let session_order: Int
            }
        }
    }
    
    /// Check if user has any plans (either local or needs to fetch)
    func checkForPlans() {
        if plans.isEmpty {
            // Try loading from storage first
            loadPlans()
            
            // If still empty and user is logged in, fetch from server
            if plans.isEmpty, let email = UserViewModel.shared.userProfile?.email {
                fetchPlansFromServer(email: email)
            }
        }
    }
    
    /// Refresh plans from server (pull to refresh)
    func refreshPlans() async {
        guard let email = UserViewModel.shared.userProfile?.email else { return }
        await fetchPlansFromServerAsync(email: email)
    }
}

extension GeneratedPlansManager {
    /// Send a newly generated plan to the backend

    private var weekdayNames: [String] {
            ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        }
    
    func savePlanToServer(routeName: String,
                          grade: String,
                          planModel: PlanModel) async throws {
        guard let email = UserViewModel.shared.userProfile?.email else {
            throw NSError(domain: "GeneratedPlansManager",
                          code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }

        // Convert your PlanModel -> ServerSaveRequest
        // Server expects: phases[] with (phase_name, description, phase_order, sessions[])
        // and sessions[] with (day, focus, details, session_order)

        var phasePayloads: [ServerSaveRequest.Phase] = []

        for (wIndex, week) in planModel.weeks.enumerated() {

            var sessionPayloads: [ServerSaveRequest.Phase.Session] = []

            for (sIndex, session) in week.sessions.enumerated() {
                // Build details text
                let warmupLine   = session.warmUp.isEmpty ? "" : "Warm-up: " + session.warmUp.joined(separator: ", ")
                let mainLine     = session.mainWorkout.isEmpty ? "" : "Main: " + session.mainWorkout.map { $0.title }.joined(separator: ", ")
                let cooldownLine = session.coolDown.isEmpty ? "" : "Cool-down: " + session.coolDown.joined(separator: ", ")
                let detailsParts = [warmupLine, mainLine, cooldownLine].filter { !$0.isEmpty }
                let details      = detailsParts.joined(separator: "\n")

                // DAY: use a short, safe label (fits VARCHAR(50))
                let dayText = weekdayNames[sIndex % weekdayNames.count]  // "Monday", "Tuesday", ...

                // FOCUS: first main workout title if present, otherwise session title; then truncate
                var focus = session.mainWorkout.first?.title ?? session.sessionTitle
                if focus.count > 50 { focus = String(focus.prefix(50)) } // DB has VARCHAR(255); 50 keeps us safe

                sessionPayloads.append(
                    .init(day: dayText,
                          focus: focus,
                          details: details,
                          session_order: sIndex + 1)
                )
            }

            // We don't have a week description field; use the plan's trainingOverview (or blank)
            let weekDescription = planModel.trainingOverview.isEmpty ? "" : planModel.trainingOverview

            phasePayloads.append(
                .init(phase_name: week.title,
                      description: weekDescription,
                      phase_order: wIndex + 1,
                      sessions: sessionPayloads)
            )
        }

        let requestBody = ServerSaveRequest(
            route_name: routeName,
            grade: grade,
            route_overview: planModel.routeOverview,
            training_overview: planModel.trainingOverview,
            phases: phasePayloads
        )

        let url = URL(string: "\(baseURL)/training_plans/\(email)/save")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addAuthHeader()
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (_, response) = try await URLSession.shared.authenticatedData(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "GeneratedPlansManager",
                          code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to save plan to server"])
        }
    }
}
