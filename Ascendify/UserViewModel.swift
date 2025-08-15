// UserViewModel.swift

import SwiftUI
import Security
import Foundation

struct UserProfile {
    var email: String? = nil
    var name: String = ""
    
    var currentClimbingGrade: String = ""
    var maxBoulderGrade: String = ""
    var goal: String = ""
    var trainingExperience: String = ""
    
    var perceivedStrengths: String = ""
    var perceivedWeaknesses: String = ""
    var attribute_ratings: String = ""
    var weeksToTrain: String = ""
    var sessionsPerWeek: String = ""
    var timePerSession: String = ""
    
    var trainingFacilities: String = ""
    var injuryHistory: String = ""
    var generalFitness: String = ""
    
    var height: String = ""
    var weight: String = ""
    var age: String = ""
    
    var preferredClimbingStyle: String = ""
    
    var onsightFlashLevel: String = ""
    var redpointingExperience: String = ""
    var sleepRecovery: String = ""
    var workLifeBalance: String = ""
    var motivationLevel: String = ""
    var accessToCoaches: String = ""
    var timeForCrossTraining: String = ""
    
    var fearFactors: String = ""
    
    var indoorVsOutdoor: String = ""
    var mindfulnessPractices: String = ""
    var additionalNotes: String = ""
}

@MainActor
final class UserViewModel: ObservableObject {
    // Allow read-only access to the singleton from background code (e.g., URLRequest extension)
    static let shared = UserViewModel()
    
    @Published var isSignedIn = false
    @Published var needsQuestionnaire = false
    @Published var userProfile: UserProfile? = nil
    @Published var showQuestionnairePrompt: Bool = false
    
    // JWT Token storage
    @Published var accessToken: String? = nil
    
    let baseURL = "http://127.0.0.1:8001"
    
    // Keys for storing auth data
    private let keychainServiceName = "com.ascendify.auth"
    private let emailKey = "userEmail"
    private let tokenKey = "accessToken"
    private let needsQuestionnaireKey = "needsQuestionnaire"
    private let userNameKey = "userName"
    private let showQuestionnairePromptKey = "showQuestionnairePrompt"
    
    init() {
        restoreAuthState()
        let storedPrompt = UserDefaults.standard.bool(forKey: showQuestionnairePromptKey)
        self.showQuestionnairePrompt = storedPrompt
    }
    
    // Helper to update and persist the flag
    func setShowQuestionnairePrompt(_ show: Bool) {
        self.showQuestionnairePrompt = show
        UserDefaults.standard.set(show, forKey: showQuestionnairePromptKey)
    }
    
    // MARK: - Authenticated Request Helper
    func authenticatedRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let token = self.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if method == "POST" || method == "PUT" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        return request
    }
    
    // MARK: - Sign Up
    func signUp(name: String, email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/signup") else {
            completion(false, "Invalid URL")
            return
        }
        
        let body: [String: String] = [
            "name": name,
            "email": email,
            "password": password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(false, "Failed to create request data")
            return
        }
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      let data = data else {
                    completion(false, "Invalid response from server")
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    // Save credentials and name
                    self.saveCredentials(email: email, password: password)
                    self.saveUserNameToDefaults(name)
                    completion(true, nil)
                } else {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let detail = json["detail"] as? String {
                        completion(false, detail)
                    } else {
                        completion(false, "Server error: \(httpResponse.statusCode)")
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/signin") else {
            completion(false, "Invalid URL")
            return
        }
        
        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(false, "Failed to create request data")
            return
        }
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      let data = data else {
                    completion(false, "Invalid response from server")
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            print("Server response: \(json)")
                            
                            // Check if response has a "data" wrapper
                            let responseData = json["data"] as? [String: Any] ?? json
                            
                            guard let userEmail = responseData["email"] as? String,
                                  let accessToken = responseData["access_token"] as? String,
                                  let refreshToken = responseData["refresh_token"] as? String else {
                                completion(false, "Invalid response format - missing required fields")
                                return
                            }
                            
                            // Store the JWT tokens
                            self.accessToken = accessToken
                            print(("✅ Access token stored: \(accessToken)"))
                            self.saveTokenToKeychain(accessToken)
                            self.saveRefreshTokenToKeychain(refreshToken)
                            
                            // ─── DECODE & PRINT JWT PAYLOAD ────────────────────────────────────────
                            if let token = self.accessToken {
                                let parts = token.split(separator: ".")
                                if parts.count == 3 {
                                    let payload = String(parts[1])
                                    if let data = Data(base64Encoded: payload.base64Padded),
                                       let jsonPayload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                        print("🔍 JWT payload: \(jsonPayload)")
                                    }
                                }
                            }
                            // ────────────────────────────────────────────────────────────────────────
                            
                            // Save credentials
                            self.saveCredentials(email: email, password: password)
                            
                            // Set signed in state
                            self.isSignedIn = true
                            
                            // Get saved name
                            let savedName = self.getUserNameFromDefaults()
                            
                            // Create basic profile
                            var basicProfile = UserProfile()
                            basicProfile.email = userEmail
                            if let name = savedName {
                                basicProfile.name = name
                            }
                            
                            self.userProfile = basicProfile
                            self.objectWillChange.send()
                            
                            SessionTrackingManager.shared.setCurrentUser(email: userEmail)
                            SessionTrackingManager.shared.clearAllData()
                            Task {
                                await SessionTrackingManager.shared.syncAllPlans()
                            }
                            
                            DiaryManager.shared.setCurrentUser(email: userEmail)
                            
                            // Fetch complete profile
                            self.fetchUserProfile(email: userEmail) { success in
                                if success {
                                    print("✅ Profile fetched after sign in")
                                    
                                    if let name = savedName, var profile = self.userProfile, profile.name.isEmpty {
                                        profile.name = name
                                        self.userProfile = profile
                                    }
                                    self.objectWillChange.send()
                                }
                                completion(true, nil)
                            }
                        } else {
                            completion(false, "Invalid response format")
                        }
                    } catch {
                        completion(false, "Error parsing response: \(error.localizedDescription)")
                    }
                } else {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let detail = json["detail"] as? String {
                        completion(false, detail)
                    } else {
                        completion(false, "Authentication failed: \(httpResponse.statusCode)")
                    }
                }
            }
        }.resume()
    }

    func refreshTokenIfNeeded(completion: @escaping (Bool) -> Void) {
        guard let refresh = getRefreshTokenFromKeychain(),
              let url = URL(string: "\(baseURL)/auth/refresh") else {
            completion(false)
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["refresh_token": refresh])

        URLSession.shared.dataTask(with: req) { data, resp, err in
            DispatchQueue.main.async {
                guard err == nil,
                      let http = resp as? HTTPURLResponse,
                      http.statusCode == 200,
                      let data = data else {
                    // Could not refresh
                    self.signOut()
                    completion(false)
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        // Check for data wrapper
                        let responseData = json["data"] as? [String: Any] ?? json
                        
                        guard let newAccess = responseData["access_token"] as? String,
                              let newRefresh = responseData["refresh_token"] as? String else {
                            self.signOut()
                            completion(false)
                            return
                        }
                        
                        // Persist updated tokens
                        self.accessToken = newAccess
                        self.saveTokenToKeychain(newAccess)
                        self.saveRefreshTokenToKeychain(newRefresh)
                        completion(true)
                    } else {
                        self.signOut()
                        completion(false)
                    }
                } catch {
                    self.signOut()
                    completion(false)
                }
            }
        }.resume()
    }
    
    /// Wraps an authenticated request: if we see a 401, it will call `refreshTokenIfNeeded`
    /// then retry exactly once.
    func performAuthenticatedRequest(
      _ makeRequest: @escaping () -> URLRequest,
      retryOnFailure: Bool = true,
      completion: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
      let request = makeRequest()
      URLSession.shared.dataTask(with: request) { data, resp, err in
        // If we got a 401 and we haven’t retried yet:
        if let http = resp as? HTTPURLResponse,
           http.statusCode == 401,
           retryOnFailure
        {
          self.refreshTokenIfNeeded { success in
            guard success else {
              // couldn’t refresh → bubble up original 401
              completion(data, resp, err)
              return
            }
            // retry exactly once, but with retryOnFailure=false now
            self.performAuthenticatedRequest(makeRequest,
                                             retryOnFailure: false,
                                             completion: completion)
          }
        } else {
          // either no 401, or we already retried
          completion(data, resp, err)
        }
      }.resume()
    }

    
    // MARK: - Fetch User Profile (with authentication)
    func fetchUserProfile(email: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/users/profile/\(email)") else {
            completion(false); return
        }

        performAuthenticatedRequest({
            self.authenticatedRequest(url: url, method: "GET")
        }) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("fetchUserProfile error:", error.localizedDescription)
                    completion(false); return
                }

                guard let http = response as? HTTPURLResponse else {
                    completion(false); return
                }

                if http.statusCode == 403 {
                    print("❌ Forbidden: Not authorized to access this profile")
                    completion(false); return
                }

                // ✅ If profile not found, treat as empty profile and keep the prompt up
                if http.statusCode == 404 {
                    print("ℹ️ No profile found for user \(email) — treating as empty profile.")
                    self.userProfile = UserProfile(email: email)
                    self.needsQuestionnaire = true
                    UserDefaults.standard.set(true, forKey: self.needsQuestionnaireKey)
                    self.setShowQuestionnairePrompt(true)
                    completion(true)
                    return
                }

                guard http.statusCode == 200,
                      let data = data,
                      let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else {
                    print("❌ Unexpected status: \(http.statusCode)")
                    completion(false); return
                }

                var profile = UserProfile()
                profile.email                    = email
                profile.name                     = jsonObj["name"] as? String ?? ""
                profile.currentClimbingGrade     = jsonObj["current_climbing_grade"] as? String ?? ""
                profile.maxBoulderGrade          = jsonObj["max_boulder_grade"] as? String ?? ""
                profile.goal                     = jsonObj["goal"] as? String ?? ""
                profile.trainingExperience       = jsonObj["training_experience"] as? String ?? ""
                profile.perceivedStrengths       = jsonObj["perceived_strengths"] as? String ?? ""
                profile.perceivedWeaknesses      = jsonObj["perceived_weaknesses"] as? String ?? ""
                profile.attribute_ratings        = jsonObj["attribute_ratings"] as? String ?? ""
                profile.weeksToTrain             = jsonObj["weeks_to_train"] as? String ?? ""
                profile.sessionsPerWeek          = jsonObj["sessions_per_week"] as? String ?? ""
                profile.timePerSession           = jsonObj["time_per_session"] as? String ?? ""
                profile.trainingFacilities       = jsonObj["training_facilities"] as? String ?? ""
                profile.injuryHistory            = jsonObj["injury_history"] as? String ?? ""
                profile.generalFitness           = jsonObj["general_fitness"] as? String ?? ""
                profile.height                   = jsonObj["height"] as? String ?? ""
                profile.weight                   = jsonObj["weight"] as? String ?? ""
                profile.age                      = jsonObj["age"] as? String ?? ""
                profile.preferredClimbingStyle   = jsonObj["preferred_climbing_style"] as? String ?? ""
                profile.indoorVsOutdoor          = jsonObj["indoor_vs_outdoor"] as? String ?? ""
                profile.onsightFlashLevel        = jsonObj["onsight_flash_level"] as? String ?? ""
                profile.redpointingExperience    = jsonObj["redpointing_experience"] as? String ?? ""
                profile.sleepRecovery            = jsonObj["sleep_recovery"] as? String ?? ""
                profile.workLifeBalance          = jsonObj["work_life_balance"] as? String ?? ""
                profile.fearFactors              = jsonObj["fear_factors"] as? String ?? ""
                profile.mindfulnessPractices     = jsonObj["mindfulness_practices"] as? String ?? ""
                profile.motivationLevel          = jsonObj["motivation_level"] as? String ?? ""
                profile.accessToCoaches          = jsonObj["access_to_coaches"] as? String ?? ""
                profile.timeForCrossTraining     = jsonObj["time_for_cross_training"] as? String ?? ""
                profile.additionalNotes          = jsonObj["additional_notes"] as? String ?? ""

                // ✅ Publish immediately for snappier UI
                self.userProfile = profile

                if !profile.name.isEmpty {
                    self.saveUserNameToDefaults(profile.name)
                }

                // Compute completion status
                let hasBasic = !profile.currentClimbingGrade.isEmpty
                            && !profile.maxBoulderGrade.isEmpty
                            && !profile.goal.isEmpty

                self.needsQuestionnaire = !hasBasic
                UserDefaults.standard.set(self.needsQuestionnaire, forKey: self.needsQuestionnaireKey)

                // ✅ Close the prompt immediately when complete
                if hasBasic {
                    self.setShowQuestionnairePrompt(false)
                }

                completion(true)
            }
        }
    }
    
    // MARK: - Submit Questionnaire (with authentication)
    func submitQuestionnaireAnswers(
        _ answers: [String: String],
        completion: @escaping (Bool) -> Void
    ) {
        // 1) Build URL
        guard let email = userProfile?.email,
              let url   = URL(string: "\(baseURL)/users/profile/\(email)") else {
            completion(false)
            return
        }

        // 2) Merge name into answers if needed
        var updatedAnswers = answers
        if !updatedAnswers.keys.contains("name"),
           let name = userProfile?.name,
           !name.isEmpty {
            updatedAnswers["name"] = name
            saveUserNameToDefaults(name)
        }

        // 3) Serialize JSON body
        guard let jsonData = try? JSONSerialization.data(withJSONObject: updatedAnswers) else {
            completion(false)
            return
        }

        // 4) Fire off the request via our retry-on-401 wrapper
        performAuthenticatedRequest({
            var req = self.authenticatedRequest(url: url, method: "PUT")
            req.httpBody = jsonData
            return req
        }) { data, response, error in
            DispatchQueue.main.async {
                // Network or other error?
                if let error = error {
                    print("Error updating user profile:", error.localizedDescription)
                    completion(false)
                    return
                }

                // Must have an HTTP response
                guard let http = response as? HTTPURLResponse else {
                    completion(false)
                    return
                }

                // If even the retry got a 401, sign out
                if http.statusCode == 401 {
                    self.signOut()
                    completion(false)
                    return
                }

                // Expect 200 OK
                guard http.statusCode == 200,
                      let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else {
                    completion(false)
                    return
                }

                // Update local UserProfile from the JSON we just sent (or from returned JSON)
                if var profile = self.userProfile {
                    for (key, value) in updatedAnswers {
                        switch key {
                        case "name":                       profile.name = value
                        case "current_climbing_grade":     profile.currentClimbingGrade = value
                        case "max_boulder_grade":          profile.maxBoulderGrade = value
                        case "goal":                       profile.goal = value
                        case "training_experience":        profile.trainingExperience = value
                        case "perceived_strengths":        profile.perceivedStrengths = value
                        case "perceived_weaknesses":       profile.perceivedWeaknesses = value
                        case "attribute_ratings":          profile.attribute_ratings = value
                        case "weeks_to_train":             profile.weeksToTrain = value
                        case "sessions_per_week":          profile.sessionsPerWeek = value
                        case "time_per_session":           profile.timePerSession = value
                        case "training_facilities":        profile.trainingFacilities = value
                        case "injury_history":             profile.injuryHistory = value
                        case "general_fitness":            profile.generalFitness = value
                        case "height":                     profile.height = value
                        case "weight":                     profile.weight = value
                        case "age":                        profile.age = value
                        case "preferred_climbing_style":   profile.preferredClimbingStyle = value
                        case "indoor_vs_outdoor":          profile.indoorVsOutdoor = value
                        case "onsight_flash_level":        profile.onsightFlashLevel = value
                        case "redpointing_experience":     profile.redpointingExperience = value
                        case "sleep_recovery":             profile.sleepRecovery = value
                        case "work_life_balance":          profile.workLifeBalance = value
                        case "fear_factors":               profile.fearFactors = value
                        case "mindfulness_practices":      profile.mindfulnessPractices = value
                        case "motivation_level":           profile.motivationLevel = value
                        case "access_to_coaches":          profile.accessToCoaches = value
                        case "time_for_cross_training":    profile.timeForCrossTraining = value
                        case "additional_notes":           profile.additionalNotes = value
                        default: break
                        }
                    }
                    self.userProfile = profile
                }

                // Clear the questionnaire flag
                self.needsQuestionnaire = false
                UserDefaults.standard.set(false, forKey: self.needsQuestionnaireKey)

                // ✅ NEW: Also hide the prompt permanently after success
                self.setShowQuestionnairePrompt(false)

                completion(true)
            }
        }
    }


    
    // MARK: - Token Management
    private func saveTokenToKeychain(_ token: String) {
        let tokenData = token.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: tokenData
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    // MARK: – Refresh Token Keychain

    private let refreshTokenKey = "refreshToken"

    private func saveRefreshTokenToKeychain(_ token: String) {
      let data = token.data(using: .utf8)!
      let query: [String: Any] = [
        kSecClass       as String: kSecClassGenericPassword,
        kSecAttrService as String: keychainServiceName,
        kSecAttrAccount as String: refreshTokenKey,
        kSecValueData   as String: data
      ]
      SecItemDelete(query as CFDictionary)
      SecItemAdd(query as CFDictionary, nil)
    }

    private func getRefreshTokenFromKeychain() -> String? {
      let query: [String: Any] = [
        kSecClass       as String: kSecClassGenericPassword,
        kSecAttrService as String: keychainServiceName,
        kSecAttrAccount as String: refreshTokenKey,
        kSecReturnData  as String: kCFBooleanTrue!,
        kSecMatchLimit  as String: kSecMatchLimitOne
      ]
      var item: AnyObject?
      guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
            let data = item as? Data,
            let token = String(data: data, encoding: .utf8)
      else { return nil }
      return token
    }
    
    private func getTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let tokenData = dataTypeRef as? Data,
              let token = String(data: tokenData, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    // MARK: - Keychain Management
    func saveCredentials(email: String, password: String) {
            UserDefaults.standard.set(email, forKey: emailKey)
        
        let passwordData = password.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: email,
            kSecValueData as String: passwordData
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func saveUserNameToDefaults(_ name: String) {
        UserDefaults.standard.set(name, forKey: userNameKey)
    }
    
    private func getUserNameFromDefaults() -> String? {
        return UserDefaults.standard.string(forKey: userNameKey)
    }
    
    private func getCredentials() -> (email: String, password: String)? {
        guard let email = UserDefaults.standard.string(forKey: emailKey) else {
            return nil
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: email,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let passwordData = dataTypeRef as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            return nil
        }
        
        return (email, password)
    }
    
    private func clearCredentials() {
        UserDefaults.standard.removeObject(forKey: emailKey)
        UserDefaults.standard.removeObject(forKey: needsQuestionnaireKey)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName
        ]
        
        SecItemDelete(query as CFDictionary)
        
        // Clear token
        self.accessToken = nil
    }
    
    private func restoreAuthState() {
        // Restore token first
        self.accessToken = getTokenFromKeychain()
        
        if let credentials = getCredentials() {
            self.needsQuestionnaire = UserDefaults.standard.bool(forKey: needsQuestionnaireKey)
            
            let savedName = getUserNameFromDefaults()
            
            var basicProfile = UserProfile()
            basicProfile.email = credentials.email
            if let name = savedName {
                basicProfile.name = name
            }
            
            self.userProfile = basicProfile
            
            // ✅ NEW: Set current user for SessionTrackingManager BEFORE auto-login
            SessionTrackingManager.shared.setCurrentUser(email: credentials.email)
            DiaryManager.shared.setCurrentUser(email: credentials.email)
            
            signIn(email: credentials.email, password: credentials.password) { success, error in
                if success {
                    if let name = savedName, var profile = self.userProfile {
                        profile.name = name
                        self.userProfile = profile
                    }
                } else {
                    self.clearCredentials()
                }
            }
        }
    }

    
    // MARK: - Sign Out
    func signOut() {
        clearCredentials()
        UserDefaults.standard.removeObject(forKey: userNameKey)
        UserDefaults.standard.removeObject(forKey: "ascendify_saved_plans")
        UserDefaults.standard.removeObject(forKey: showQuestionnairePromptKey)
        self.showQuestionnairePrompt = false
        
        for (key, _) in UserDefaults.standard.dictionaryRepresentation() {
            if key.hasPrefix("cached_projects_") {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        
        SessionTrackingManager.shared.clearForSignOut()
        DiaryManager.shared.clearForSignOut()
        
        self.userProfile = nil
        self.isSignedIn = false
        self.needsQuestionnaire = false
    }
    
    // MARK: - Request Password Reset
    func requestPasswordReset(email: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(baseURL)/auth/forgot-password") else {
            completion(false, "Invalid URL")
            return
        }
        
        let body: [String: String] = ["email": email]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(false, "Failed to create request")
            return
        }
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(false, "Invalid response from server")
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    completion(true, "Password reset instructions have been sent to your email.")
                } else {
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let detail = json["detail"] as? String {
                        completion(false, detail)
                    } else {
                        completion(false, "Failed to request password reset. Please try again later.")
                    }
                }
            }
        }
    }
}

// Extensions

extension UserViewModel {
  /// Perform a data task, automatically refreshing the token once on a 401.
  func dataWithRefresh(
    _ makeRequest: @escaping () -> URLRequest
  ) async throws -> (Data, URLResponse) {
    // 1) First attempt
    var request = makeRequest()
    let (data, response) = try await URLSession.shared.data(for: request)
    
    // 2) If 401, try refresh
    if let http = response as? HTTPURLResponse, http.statusCode == 401 {
      let refreshed = await withCheckedContinuation { cont in
        self.refreshTokenIfNeeded { success in
          cont.resume(returning: success)
        }
      }
      guard refreshed else {
        // could not refresh → force sign-out & error
        self.signOut()
        throw URLError(.userAuthenticationRequired)
      }
      
      // 3) Retry with fresh token
      request = makeRequest() // rebuild with new accessToken
      return try await URLSession.shared.data(for: request)
    }
    
    return (data, response)
  }
}

extension UserViewModel {
    /// Deletes the user's account (and all data) with automatic token-refresh on 401.
    func deleteAccount(completion: @escaping (Bool, String?) -> Void) {
        guard let email = userProfile?.email,
              let url = URL(string: "\(baseURL)/users/profile/\(email)")
        else {
            completion(false, "Invalid URL or missing email")
            return
        }

        // Use your retry-on-401 helper
        performAuthenticatedRequest({
            self.authenticatedRequest(url: url, method: "DELETE")
        }) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "Network error: \(error.localizedDescription)")
                    return
                }

                guard let http = response as? HTTPURLResponse else {
                    completion(false, "Invalid server response")
                    return
                }

                // Treat 200 and 204 as success
                if http.statusCode == 200 || http.statusCode == 204 {
                    // success: user deleted
                    self.signOut()
                    completion(true, nil)
                } else {
                    // Parse any error detail
                    var message = "Server error: \(http.statusCode)"
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let detail = json["detail"] as? String {
                        message = detail
                    }
                    completion(false, message)
                }
            }
        }
    }
}


extension UserViewModel {
  /// Async version of fetchUserProfile
  func fetchUserProfile(email: String) async throws -> UserProfile {
    // 1) Build the URL
    let url = URL(string: "\(baseURL)/users/profile/\(email)")!
    
    // 2) Send request (auto-refresh on 401)
    let (data, response) = try await dataWithRefresh {
      self.authenticatedRequest(url: url, method: "GET")
    }
    
    // 3) Verify we got a 200
    guard let http = response as? HTTPURLResponse,
          http.statusCode == 200
    else {
      throw URLError(.badServerResponse)
    }
    
    // 4) Parse JSON into a UserProfile
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    var profile = UserProfile()
    profile.email                   = email
    profile.name                    = json["name"] as? String ?? ""
    profile.currentClimbingGrade    = json["current_climbing_grade"] as? String ?? ""
    profile.maxBoulderGrade         = json["max_boulder_grade"] as? String ?? ""
    profile.goal                    = json["goal"] as? String ?? ""
    profile.trainingExperience      = json["training_experience"] as? String ?? ""
    profile.perceivedStrengths      = json["perceived_strengths"] as? String ?? ""
    profile.perceivedWeaknesses     = json["perceived_weaknesses"] as? String ?? ""
    profile.attribute_ratings       = json["attribute_ratings"] as? String ?? ""
    profile.weeksToTrain            = json["weeks_to_train"] as? String ?? ""
    profile.sessionsPerWeek         = json["sessions_per_week"] as? String ?? ""
    profile.timePerSession          = json["time_per_session"] as? String ?? ""
    profile.trainingFacilities      = json["training_facilities"] as? String ?? ""
    profile.injuryHistory           = json["injury_history"] as? String ?? ""
    profile.generalFitness          = json["general_fitness"] as? String ?? ""
    profile.height                  = json["height"] as? String ?? ""
    profile.weight                  = json["weight"] as? String ?? ""
    profile.age                     = json["age"] as? String ?? ""
    profile.preferredClimbingStyle  = json["preferred_climbing_style"] as? String ?? ""
    profile.indoorVsOutdoor         = json["indoor_vs_outdoor"] as? String ?? ""
    profile.onsightFlashLevel       = json["onsight_flash_level"] as? String ?? ""
    profile.redpointingExperience   = json["redpointing_experience"] as? String ?? ""
    profile.sleepRecovery           = json["sleep_recovery"] as? String ?? ""
    profile.workLifeBalance         = json["work_life_balance"] as? String ?? ""
    profile.fearFactors             = json["fear_factors"] as? String ?? ""
    profile.mindfulnessPractices    = json["mindfulness_practices"] as? String ?? ""
    profile.motivationLevel         = json["motivation_level"] as? String ?? ""
    profile.accessToCoaches         = json["access_to_coaches"] as? String ?? ""
    profile.timeForCrossTraining    = json["time_for_cross_training"] as? String ?? ""
    profile.additionalNotes         = json["additional_notes"] as? String ?? ""
    
    return profile
  }
}

// MARK: - Token Expiration Check
extension UserViewModel {
    /// Checks if the current access token has expired (with a 60-sec buffer)
    func isTokenExpired() -> Bool {
        guard let token = accessToken else { return true }
        let segments = token.split(separator: ".")
        guard segments.count == 3,
              let payloadData = Data(base64Encoded: String(segments[1]).base64Padded)
        else {
            return true
        }

        guard let payload = try? JSONSerialization
                .jsonObject(with: payloadData) as? [String: Any],
              let exp = payload["exp"] as? TimeInterval
        else {
            return true
        }

        let expirationDate = Date(timeIntervalSince1970: exp)
        let buffer: TimeInterval = 60
        return Date().addingTimeInterval(buffer) > expirationDate
    }

    /// Proactively refresh the token only if it’s expired (or about to)
    func refreshTokenIfNeeded() async -> Bool {
            // Don’t call the network unless the token is really expired
            guard isTokenExpired() else { return true }
            return await withCheckedContinuation { cont in
                refreshTokenIfNeeded { success in
                    cont.resume(returning: success)
                }
            }
    }
}

// MARK: - Base64 Padding Helper
private extension String {
    var base64Padded: String {
        let remainder = count % 4
        return remainder > 0
            ? self + String(repeating: "=", count: 4 - remainder)
            : self
    }
}

extension UserViewModel {
    func debugJWTToken() {
        guard let token = self.accessToken else {
            print("❌ No access token available")
            return
        }
        
        print("🔍 JWT TOKEN DEBUG:")
        print("  Full token length: \(token.count)")
        print("  First 50 chars: \(String(token.prefix(50)))")
        
        // Split JWT into parts
        let parts = token.split(separator: ".")
        if parts.count == 3 {
            let header = String(parts[0])
            let payload = String(parts[1])
            let signature = String(parts[2])
            
            print("  Header length: \(header.count)")
            print("  Payload length: \(payload.count)")
            print("  Signature length: \(signature.count)")
            
            // Try to decode the payload
            if let payloadData = Data(base64Encoded: payload.base64Padded),
               let jsonPayload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] {
                print("🔍 JWT PAYLOAD:")
                for (key, value) in jsonPayload {
                    print("    \(key): \(value)")
                }
                
                if let email = jsonPayload["email"] as? String {
                    print("🔍 EMAIL FROM JWT:")
                    print("    Raw email: '\(email)'")
                    print("    Email length: \(email.count)")
                    print("    Email bytes: \(email.data(using: .utf8)?.map { String($0) }.joined(separator: ",") ?? "nil")")
                    print("    Trimmed email: '\(email.trimmingCharacters(in: .whitespacesAndNewlines))'")
                }
            } else {
                print("❌ Failed to decode JWT payload")
            }
        } else {
            print("❌ Invalid JWT format - expected 3 parts, got \(parts.count)")
        }
    }
}
