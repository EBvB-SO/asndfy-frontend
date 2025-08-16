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
    private let plansStorageKey = "ascendify_saved_plans"
    
    @Published var plans: [PlanWrapper] = []
    @Published var isLoading = false
    @Published var error: String? = nil
    
    // MARK: - Helpers
    @inline(__always)
    private func currentEmail() async -> String? {
        await MainActor.run {
            UserViewModel.shared.userProfile?.email
        }
    }
    
    @inline(__always)
    private func addAuthHeader(_ request: inout URLRequest) async {
        await MainActor.run {
            request.addAuthHeader()
        }
    }
    
    init() {
        loadPlans()
    }
    
    // MARK: - Local Plan Management
    
    func savePlan(routeName: String, grade: String,
                  plan: PlanModel, serverId: String? = nil) {
        let newPlan = PlanWrapper(serverId: serverId,
                                  routeName: routeName,
                                  grade: grade,
                                  plan: plan)
        plans.append(newPlan)
        savePlansToStorage()
    }
    
    func deletePlan(at index: Int) {
        guard plans.indices.contains(index) else { return }
        plans.remove(at: index)
        savePlansToStorage()
    }
    
    private func savePlansToStorage() {
        do {
            let data = try JSONEncoder().encode(plans)
            UserDefaults.standard.set(data, forKey: plansStorageKey)
            print("✅ Saved \(plans.count) plans to storage")
        } catch {
            print("⚠️ Error saving plans to storage: \(error.localizedDescription)")
        }
    }
    
    private func loadPlans() {
        guard let data = UserDefaults.standard.data(forKey: plansStorageKey) else {
            print("No saved plans found in storage")
            return
        }
        do {
            plans = try JSONDecoder().decode([PlanWrapper].self, from: data)
            print("✅ Loaded \(plans.count) plans from storage")
            pruneCachesForCurrentPlans()
        } catch {
            print("⚠️ Error loading plans: \(error.localizedDescription)")
        }
    }
    
    func clearPlans() {
        plans = []
        UserDefaults.standard.removeObject(forKey: plansStorageKey)
        pruneCachesForCurrentPlans()
    }
    
    private func planIdentifier(for wrapper: PlanWrapper) -> String {
        if let sid = wrapper.serverId, !sid.isEmpty {
            return sid.lowercased()
        }
        return "\(wrapper.routeName)_\(wrapper.grade)"
            .replacingOccurrences(of: " ", with: "_")
            .lowercased()
    }
    
    private func pruneCachesForCurrentPlans() {
        let ids = Set(plans.map { planIdentifier(for: $0) })
        SessionTrackingManager.shared.pruneOrphanPlanData(currentPlanIds: ids)
    }
    
    // MARK: - Server Interaction
    
    func fetchPlansFromServer(email: String) {
        Task { await fetchPlansFromServerAsync(email: email) }
    }
    
    @MainActor
    private func fetchPlansFromServerAsync(email: String) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            let url = URL(string: "\(baseURL)/training_plans/\(email)")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addAuthHeader()
            
            let (data, response) = try await URLSession.shared.authenticatedData(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw NSError(domain: "GeneratedPlansManager", code: 0,
                              userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }
            
            switch http.statusCode {
            case 200:
                let serverPlans = try JSONDecoder().decode([ServerPlanModel].self, from: data)
                self.plans = serverPlans.map { serverPlan in
                    let planModel = PlanModel(
                        routeOverview: serverPlan.route_overview,
                        trainingOverview: serverPlan.training_overview,
                        weeks: serverPlan.phases
                    )
                    return PlanWrapper(
                        serverId: serverPlan.id,
                        routeName: serverPlan.route_name,
                        grade: serverPlan.grade,
                        plan: planModel
                    )
                }
                savePlansToStorage()
                pruneCachesForCurrentPlans()
                print("✅ Fetched \(plans.count) plans from server")
            case 404:
                self.plans = []
                savePlansToStorage()
                pruneCachesForCurrentPlans()
                print("No plans found for user")
            default:
                if let errorData = try? JSONDecoder().decode([String:String].self, from: data),
                   let detail = errorData["detail"] {
                    throw NSError(domain: "GeneratedPlansManager", code: http.statusCode,
                                  userInfo: [NSLocalizedDescriptionKey: detail])
                } else {
                    throw NSError(domain: "GeneratedPlansManager", code: http.statusCode,
                                  userInfo: [NSLocalizedDescriptionKey: "Server error: \(http.statusCode)"])
                }
            }
        } catch {
            self.error = "Error fetching plans: \(error.localizedDescription)"
            print("⚠️ Error fetching plans: \(error)")
            if plans.isEmpty { loadPlans() }
        }
    }
    
    func syncPlansWithServer() async {
        guard let email = await currentEmail() else { return }
        await fetchPlansFromServerAsync(email: email)
    }
    
    func deletePlanFromServer(planId: String) async throws {
        guard let email = await currentEmail() else {
            throw NSError(domain: "GeneratedPlansManager", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        let url = URL(string: "\(baseURL)/training_plans/\(email)/\(planId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        await addAuthHeader(&request)
        
        let (_, response) = try await URLSession.shared.authenticatedData(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...204).contains(http.statusCode) else {
            throw NSError(domain: "GeneratedPlansManager",
                          code: (response as? HTTPURLResponse)?.statusCode ?? 0,
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
    
    private struct SavePlanResponse: Decodable {
        let success: Bool
        let message: String
        let plan_id: String
    }
    
    @MainActor
    func checkForPlans() {
        if plans.isEmpty {
            loadPlans()
            if plans.isEmpty, let email = UserViewModel.shared.userProfile?.email {
                fetchPlansFromServer(email: email)
            }
        }
    }
    
    func refreshPlans() async {
        guard let email = await currentEmail() else { return }
        await fetchPlansFromServerAsync(email: email)
    }
}

// MARK: - Deletion Helper
extension GeneratedPlansManager {
    @MainActor
    func deletePlanEverywhere(at index: Int) async {
        guard plans.indices.contains(index) else { return }
        let wrapper = plans[index]
        let sid = wrapper.serverId
        plans.remove(at: index)
        savePlansToStorage()
        pruneCachesForCurrentPlans()
        
        if let sid {
            do { try await deletePlanFromServer(planId: sid) }
            catch { print("⚠️ Server delete failed for plan \(sid): \(error.localizedDescription)") }
        }
    }
}

// MARK: - Save to Server
extension GeneratedPlansManager {
    private var weekdayNames: [String] {
        ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
    }
    
    func savePlanToServer(routeName: String,
                          grade: String,
                          planModel: PlanModel) async throws -> String {
        guard let email = await currentEmail() else {
            throw NSError(domain: "GeneratedPlansManager", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
        }
        
        var phasePayloads: [ServerSaveRequest.Phase] = []
        var globalSessionCounter = 0
        
        for (wIndex, week) in planModel.weeks.enumerated() {
            var sessionPayloads: [ServerSaveRequest.Phase.Session] = []
            for session in week.sessions {
                let dayText: String
                if let day = SessionTrackingManager.shared.extractDayFromSessionTitle(session.sessionTitle) {
                    dayText = day
                } else {
                    dayText = weekdayNames[globalSessionCounter % weekdayNames.count]
                }
                
                var focus = session.mainWorkout.first?.title ?? session.sessionTitle
                if focus.count > 50 { focus = String(focus.prefix(50)) }
                
                let warmupLine   = session.warmUp.isEmpty ? "" : "Warm-up: " + session.warmUp.joined(separator: ", ")
                let mainLine     = session.mainWorkout.isEmpty ? "" : "Main: " + session.mainWorkout.map { $0.title }.joined(separator: ", ")
                let cooldownLine = session.coolDown.isEmpty ? "" : "Cool-down: " + session.coolDown.joined(separator: ", ")
                let details = [warmupLine, mainLine, cooldownLine].filter { !$0.isEmpty }.joined(separator: "\n")
                
                globalSessionCounter += 1
                
                sessionPayloads.append(.init(day: dayText,
                                             focus: focus,
                                             details: details,
                                             session_order: globalSessionCounter))
            }
            
            let weekDescription = planModel.trainingOverview.isEmpty ? "" : planModel.trainingOverview
            phasePayloads.append(.init(phase_name: week.title,
                                       description: weekDescription,
                                       phase_order: wIndex + 1,
                                       sessions: sessionPayloads))
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
        await addAuthHeader(&request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.authenticatedData(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "GeneratedPlansManager",
                          code: (response as? HTTPURLResponse)?.statusCode ?? 0,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to save plan to server"])
        }
        
        let serverResponse = try JSONDecoder().decode(SavePlanResponse.self, from: data)
        return serverResponse.plan_id
    }
}
