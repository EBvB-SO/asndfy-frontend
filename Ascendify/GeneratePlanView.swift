//
//  GeneratePlanView.swift
//  Ascendify
//
//  Created by Ellis Barker on 08/02/2025.
//

import SwiftUI

struct GeneratePlanView: View {
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userViewModel: UserViewModel
    
    // Basic route information
    @State private var routeName = ""
    @State private var routeGrade = ""
    @State private var routeCrag = ""
    
    // Route characteristic selections
    @State private var selectedAngle = Set<RouteAngle>()
    @State private var selectedLength = Set<RouteLength>()
    @State private var selectedHoldType = Set<HoldType>()
    @State private var selectedRouteStyle: RouteStyle? = nil
    @State private var routeDescription = ""
    
    // ADDED: Training duration fields
    @State private var weeksToTrain = "8"
    @State private var sessionsPerWeek = "4"
    @State private var timePerSession = "2"
    
    @State private var showPreview = false
    
    // New state for the two-step process
    @State private var previewData: PlanPreviewData? = nil
    @State private var inputPayload: [String: String]? = nil
    
    @State private var taskID: String?             = nil
    @State private var generationProgress: Int      = 0
    @State private var fullPlan: PlanConverter.PhaseBasedPlan? = nil
    @State private var isGenerating = false
    @State private var errorMessage: String?
    
    // BaseURL
    private let baseURL = "http://127.0.0.1:8001"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HeaderView()  // custom SwiftUI headertruct ProjectsView
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Section 1: Basic Route Information
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Route Information")
                                .font(.headline)
                                .foregroundColor(.deepPurple)
                            
                            TextField("Route Name", text: $routeName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Grade (e.g. 7c+)", text: $routeGrade)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Crag (where is it?)", text: $routeCrag)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Section 2: Route Characteristics
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Route Characteristics")
                                .font(.headline)
                                .foregroundColor(.deepPurple)
                            
                            // Route Angle Selection
                            RouteCharacteristicSelector(
                                title: "Route Angle",
                                description: "What angles does your route have? (Select all that apply)",
                                options: RouteAngle.allCases,
                                selectedOptions: $selectedAngle
                            )
                            
                            // Route Length Selection
                            RouteCharacteristicSelector(
                                title: "Route Length",
                                description: "How would you characterize the length? (Select all that apply)",
                                options: RouteLength.allCases,
                                selectedOptions: $selectedLength
                            )
                            
                            // Hold Type Selection
                            RouteCharacteristicSelector(
                                title: "Hold Types",
                                description: "What types of holds are on the route? (Select all that apply)",
                                options: HoldType.allCases,
                                selectedOptions: $selectedHoldType
                            )
                            
                            // Route Style Selection - Single Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Route Style")
                                    .font(.subheadline)
                                    .foregroundColor(.tealBlue)
                                
                                Text("How would you describe the overall style? (Select one)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                    ForEach(RouteStyle.allCases) { style in
                                        Button {
                                            selectedRouteStyle = style
                                        } label: {
                                            HStack {
                                                Image(systemName: style.iconName)
                                                    .foregroundColor(selectedRouteStyle == style ? .purple : .gray)
                                                Text(style.rawValue)
                                                    .fontWeight(selectedRouteStyle == style ? .semibold : .regular)
                                                Spacer()
                                                if selectedRouteStyle == style {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.purple)
                                                }
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selectedRouteStyle == style ? Color.purple.opacity(0.1) : Color(.systemGray6))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(selectedRouteStyle == style ? Color.purple : .clear, lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            
                            // Additional description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Additional Route Description (Optional)")
                                    .font(.subheadline)
                                    .foregroundColor(.tealBlue)
                                
                                Text("Any other details that might help tailor your training plan?")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                TextEditor(text: $routeDescription)
                                    .frame(minHeight: 100)
                                    .padding(4)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Training Duration
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Training Duration")
                                .font(.headline)
                                .foregroundColor(.deepPurple)
                            
                            // Training duration pickers in a horizontal layout
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Weeks to Train")
                                        .font(.subheadline)
                                        .foregroundColor(.tealBlue)
                                    
                                    Picker("Weeks to Train", selection: $weeksToTrain) {
                                        ForEach(4...12, id: \.self) { num in
                                            Text("\(num) weeks").tag("\(num)")
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 100)
                                    .clipped()
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("Sessions per Week")
                                        .font(.subheadline)
                                        .foregroundColor(.tealBlue)
                                    
                                    Picker("Sessions per Week", selection: $sessionsPerWeek) {
                                        ForEach(1...6, id: \.self) { num in
                                            Text("\(num) session\(num > 1 ? "s" : "")").tag("\(num)")
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 100)
                                    .clipped()
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("Hours per Session")
                                        .font(.subheadline)
                                        .foregroundColor(.tealBlue)
                                    
                                    Picker("Hours", selection: $timePerSession) {
                                        ForEach(1...3, id: \.self) { hr in
                                            Text("\(hr) hour\(hr > 1 ? "s" : "")").tag("\(hr)")
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 100)
                                    .clipped()
                                }
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .padding(.bottom, 10)
                        }
                        .padding(.horizontal)
                        
                        // Generate button section
                        VStack {
                            if let error = errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .padding(.bottom, 4)
                            }
                            
                            if isGenerating {
                                ProgressView("Generating Preview...")
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                Button(action: generatePlanAsync) {
                                    Text("Generate Plan")
                                        .foregroundColor(.offWhite)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                                .background(isFormValid ? Color.ascendGreen : Color.gray)
                                .cornerRadius(10)
                                .disabled(!isFormValid)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showPreview) {
                if let preview = previewData, let payload = inputPayload {
                    // Show a preview with PlanPreviewView
                    PlanPreviewView(
                        routeName: routeName,
                        grade: routeGrade,
                        previewData: preview,
                        userInputData: payload,
                        onPurchaseComplete: { plan in
                            Task {
                                do {
                                    try await GeneratedPlansManager.shared.savePlanToServer(
                                        routeName: self.routeName,
                                        grade: self.routeGrade,
                                        planModel: plan
                                    )
                                    GeneratedPlansManager.shared.savePlan(
                                        routeName: self.routeName,
                                        grade: self.routeGrade,
                                        plan: plan
                                    )
                                    dismiss()
                                } catch {
                                    self.errorMessage = error.localizedDescription
                                }
                            }
                        }
                    )
                    .environmentObject(userViewModel)
                }
            }
        }
    }
    
    // Validation check
    private var isFormValid: Bool {
        !routeName.isEmpty &&
        !routeGrade.isEmpty &&
        !routeCrag.isEmpty &&
        !selectedAngle.isEmpty &&
        !selectedLength.isEmpty &&
        !selectedHoldType.isEmpty &&
        selectedRouteStyle != nil
    }
    
    private func generatePlanAsync() {
        isGenerating = true
        errorMessage  = nil
        
        guard let profile = userViewModel.userProfile else {
            errorMessage = "No user profile found. Please complete the questionnaire."
            isGenerating = false
            return
        }
        
        // Build payload for the preview with our route details
        let payload: [String: Any] = [
            "route": routeName,
            "grade": routeGrade,
            "crag": routeCrag,
            
            // Add the route characteristics
            "route_angles": selectedAngle.map { $0.rawValue }.joined(separator: ", "),
            "route_lengths": selectedLength.map { $0.rawValue }.joined(separator: ", "),
            "hold_types": selectedHoldType.map { $0.rawValue }.joined(separator: ", "),
            "route_style": selectedRouteStyle?.rawValue ?? "",
            "route_description": routeDescription,
            
            // From GeneratePlanView
            "weeks_to_train": weeksToTrain,
            "sessions_per_week": sessionsPerWeek,
            "time_per_session": timePerSession,
            
            // User profile information
            "current_climbing_grade": profile.currentClimbingGrade,
            "max_boulder_grade": profile.maxBoulderGrade,
            "training_experience": profile.trainingExperience,
            "perceived_strengths": profile.perceivedStrengths,
            "perceived_weaknesses": profile.perceivedWeaknesses,
            "attribute_ratings": profile.attribute_ratings,
            "training_facilities": profile.trainingFacilities,
            "injury_history": profile.injuryHistory,
            "general_fitness": profile.generalFitness,
            "height": profile.height,
            "weight": profile.weight,
            "age": profile.age,
            "preferred_climbing_style": profile.preferredClimbingStyle,
            "indoor_vs_outdoor": profile.indoorVsOutdoor,
            "onsight_flash_level": profile.onsightFlashLevel,
            "redpointing_experience": profile.redpointingExperience,
            "sleep_recovery": profile.sleepRecovery,
            "work_life_balance": profile.workLifeBalance,
            "fear_factors": profile.fearFactors,
            "mindfulness_practices": profile.mindfulnessPractices,
            "motivation_level": profile.motivationLevel,
            "access_to_coaches": profile.accessToCoaches,
            "time_for_cross_training": profile.timeForCrossTraining,
            "additional_notes": profile.additionalNotes
        ]
        
        guard let url = URL(string: "\(baseURL)/training_plans/generate_preview") else {
            self.errorMessage = "Invalid URL"
            self.isGenerating = false
            return
        }
        
        // Log the request details
        print("🔵 Generating plan preview...")
        print("🔵 URL: \(url)")
        print("🔵 Payload keys: \(payload.keys.joined(separator: ", "))")
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 120.0
        
        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
            print("🔵 Request body size: \(req.httpBody?.count ?? 0) bytes")
        } catch {
            self.errorMessage = "Failed to serialize payload"
            self.isGenerating = false
            return
        }
            
        print("🔵 Sending request...")

        Task {
            do {
                // Add auth on main actor (since addAuthHeader is @MainActor)
                var request = req
                await MainActor.run { request.addAuthHeader() }

                let (data, resp) = try await URLSession.shared.authenticatedData(for: request)

                guard let http = resp as? HTTPURLResponse else {
                    await MainActor.run {
                        self.errorMessage = "Invalid response"
                        self.isGenerating = false
                    }
                    return
                }

                print("🔵 HTTP Status: \(http.statusCode)")

                guard http.statusCode == 200 else {
                    let msg: String
                    if let server = try? JSONDecoder().decode(ServerError.self, from: data) {
                        msg = server.detail
                    } else if let txt = String(data: data, encoding: .utf8) {
                        msg = "Server error (\(http.statusCode)): \(txt)"
                    } else {
                        msg = "Server error: \(http.statusCode)"
                    }
                    await MainActor.run {
                        self.errorMessage = msg
                        self.isGenerating = false
                    }
                    return
                }

                // Decode the preview payload
                let preview = try JSONDecoder().decode(PlanPreviewData.self, from: data)

                await MainActor.run {
                    self.previewData  = preview
                    self.inputPayload = payload.mapValues { "\($0)" }
                    self.showPreview  = true
                    self.isGenerating = false
                }

            } catch {
                await MainActor.run {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    self.isGenerating = false
                }
            }
        }
    }
        
        // MARK: – Step 2: Poll for updates
        private func pollPlanStatus() {
            guard let taskID = taskID else { return }
            
            let url = URL(string: "\(baseURL)/training_plans/plan_status/\(taskID)")!
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            
            Task {
                do {
                    var request = req
                    await MainActor.run { request.addAuthHeader() }

                    let (data, resp) = try await URLSession.shared.authenticatedData(for: request)

                    guard let http = resp as? HTTPURLResponse else {
                        await MainActor.run {
                            self.errorMessage = "Invalid status response"
                            self.isGenerating = false
                        }
                        return
                    }

                    guard http.statusCode == 200 else {
                        let msg = String(data: data, encoding: .utf8) ?? "Server error"
                        await MainActor.run {
                            self.errorMessage = msg
                            self.isGenerating = false
                        }
                        return
                    }

                    let status = try JSONDecoder().decode(StatusResponse.self, from: data)

                    switch status.status {
                    case "processing":
                        await MainActor.run {
                            self.generationProgress = status.progress ?? 0
                        }
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        self.pollPlanStatus()

                    case "complete":
                        if let plan = status.plan {
                            await MainActor.run {
                                self.fullPlan = plan
                                self.showPreview = true
                                self.isGenerating = false
                            }
                        } else {
                            await MainActor.run {
                                self.errorMessage = "No plan returned"
                                self.isGenerating = false
                            }
                        }

                    case "error":
                        await MainActor.run {
                            self.errorMessage = status.message ?? "Unknown error"
                            self.isGenerating = false
                        }

                    default:
                        await MainActor.run {
                            self.errorMessage = "Unexpected status: \(status.status ?? "unknown")"
                            self.isGenerating = false
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Network error: \(error.localizedDescription)"
                        self.isGenerating = false
                    }
                }
            }
        }
        
        // MARK: — Polling helpers —
        struct TaskIDResponse: Decodable {
            let task_id: String
        }
        
    struct StatusResponse: Decodable {
        let status: String?
        let progress: Int?
        let plan: PlanConverter.PhaseBasedPlan?
        let message: String?
        
        // Handle case where the response IS the plan
        let phases: [PlanConverter.PhaseBasedPlan.Phase]?
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // Try normal status response first
            if container.contains(.status) {
                status = try container.decode(String.self, forKey: .status)
                progress = try container.decodeIfPresent(Int.self, forKey: .progress)
                plan = try container.decodeIfPresent(PlanConverter.PhaseBasedPlan.self, forKey: .plan)
                message = try container.decodeIfPresent(String.self, forKey: .message)
                phases = nil
            } else {
                // Response IS the plan
                status = "complete"
                progress = 100
                message = nil
                phases = try container.decode([PlanConverter.PhaseBasedPlan.Phase].self, forKey: .phases)
                plan = PlanConverter.PhaseBasedPlan(routeOverview: nil, trainingOverview: nil, phases: phases!)
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case status, progress, plan, message, phases
        }
    }
                
        // You must define this to match your server’s JSON:
        struct FullPlanResponse: Decodable {
            let route_overview: String
            let training_overview: String
            let phases: [Phase]
            
            struct Phase: Decodable {
                let phase_name: String
                let description: String
                let weekly_schedule: [Day]
                
                struct Day: Decodable {
                    let day: String
                    let focus: String
                    let details: String
                }
            }
        }
    }
