//
//  PlanPreviewView.swift
//  Ascendify
//
//  Created by Ellis Barker on 08/02/2025.
//

import SwiftUI

struct PlanPreviewView: View {
    let routeName: String
    let grade: String
    let previewData: PlanPreviewData
    let userInputData: [String: String]
    private let baseURL = "http://127.0.0.1:8001" // Change to your production server URL later
    
    // Callback function that takes a PlanModel and returns void
    let onPurchaseComplete: (PlanModel) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var isPurchasing = false
    @State private var purchaseError: String? = nil
    
    // New states for tracking generation progress
    @State private var currentGenerationStep = 0
    @State private var showWebView = false
    
    // Define GenerationProgressView BEFORE the body
        struct GenerationProgressView: View {
            let currentStep: Int
            
            var body: some View {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Plan Generation Progress")
                        .font(.headline)
                        .foregroundColor(.tealBlue)
                    
                    if #available(iOS 14.0, *) {
                        ProgressView(value: Float(currentStep), total: 5.0)
                    }
                    
                    Text(stepText)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            private var stepText: String {
                let stepTexts = [
                    "Analyzing route characteristics...",
                    "Evaluating your climber profile...",
                    "Selecting optimal exercises for your needs...",
                    "Structuring training phases...",
                    "Finalizing your detailed plan..."
                ]
                
                return currentStep < stepTexts.count ? stepTexts[currentStep] : "Finalizing your plan..."
            }
        }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom header with back button
            DetailHeaderView {
                dismiss()
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    // Route title and grade
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(routeName) Training Plan")
                            .font(.title)
                            .bold()
                            .foregroundColor(.deepPurple)
                            .padding(.bottom, 5)
                        
                        if !grade.isEmpty {
                            Text("Grade: \(grade)")
                                .font(.headline)
                                .foregroundColor(.tealBlue)
                                .padding(.bottom, 5)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Container to ensure all cards have the same width
                    VStack(spacing: 16) {
                        // Route Overview Card
                        CardView(title: "Route Overview") {
                            Text(previewData.routeOverview)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // Training Approach Card
                        CardView(title: "Training Approach") {
                            Text(previewData.trainingApproach)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // What you'll get section
                        CardView(title: "What You'll Get") {
                            VStack(alignment: .leading, spacing: 8) {
                                FeatureRow(icon: "calendar", text: "Personalised weekly training plan")
                                FeatureRow(icon: "figure.climbing", text: "Sport-specific climbing exercises")
                                FeatureRow(icon: "chart.bar.fill", text: "Progressive training phases")
                                FeatureRow(icon: "flame.fill", text: "Targeted strength & endurance workouts")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal)
                    
                    // If generation in progress, show generation progress view
                    if isPurchasing {
                        // Make this a separate view with padding to ensure it's visible
                        GenerationProgressView(currentStep: currentGenerationStep)
                            .padding(.vertical, 20)
                            .padding(.horizontal)
                    }
                    
                    if let purchaseError = purchaseError {
                        Text(purchaseError)
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.8))
                            )
                            .padding(.horizontal)
                    }
                    
                    // Add extra space when generating to push content up
                    if isPurchasing {
                        Spacer().frame(height: 100)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 20)
            }
            
            // Bottom purchase button area with gradient background
            VStack {
                if isPurchasing {
                    // Enhanced loading state
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.bottom, 5)
                        
                        Text("Generating your plan...")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("This may take 1-2 minutes for complex plans")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.ascendGreen, .tealBlue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                } else {
                    // Styled purchase button
                    Button(action: purchasePlan) {
                        HStack {
                            Text("Purchase Training Plan")
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text("£5.99")
                                .fontWeight(.bold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.3))
                                .cornerRadius(15)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.ascendGreen, .tealBlue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                        .shadow(color: Color.ascendGreen.opacity(0.5), radius: 5, x: 0, y: 3)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 15)
                }
            }
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: -2)
        }
        .navigationBarHidden(true)
        .background(Color(.systemGray6).opacity(0.5).edgesIgnoringSafeArea(.all))
        .onAppear {
            // Reset progress when view appears
            currentGenerationStep = 0
        }
    }
    
    // Create a separate view for the generation progress
    private func purchasePlan() {
        isPurchasing = true
        purchaseError = nil
        currentGenerationStep = 0
        
        // Process payment first
        PaymentManager.shared.purchasePlan { success in
            if !success {
                isPurchasing = false
                purchaseError = "Payment failed"
                return
            }
            
            // If payment succeeded, initiate the step-by-step generation process
            startStepByStepGeneration()
        }
    }
    
    private func startStepByStepGeneration() {
        // Step 1: Analyze route characteristics (advance after delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.currentGenerationStep = 1
            
            // Step 2: Evaluate climber profile
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.currentGenerationStep = 2
                
                // Step 3: Select optimal exercises
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    self.currentGenerationStep = 3
                    
                    // Step 4: Structure training phases
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.currentGenerationStep = 4
                        
                        // Step 5: Generate detailed plan (actual API call)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.currentGenerationStep = 5
                            
                            // Now actually generate the full plan
                            self.generateFullPlan()
                        }
                    }
                }
            }
        }
    }
    
    // In PlanPreviewView.swift
    private func generateFullPlan() {
        // Convert string values to proper types
        let weeksToTrain = Int(userInputData["weeks_to_train"] ?? "8") ?? 8
        let sessionsPerWeek = Int(userInputData["sessions_per_week"] ?? "4") ?? 4
        
        // Extract years from training_experience
        let yearsExp: String = {
            let exp = userInputData["training_experience"] ?? ""
            if let match = exp.range(of: #"(\d+)\s*(?:year|yr)"#, options: .regularExpression) {
                let yearStr = String(exp[match]).components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                return yearStr
            }
            return "0"
        }()
        
        // Convert that string into a Double so JSONSerialization emits a number
        let yearsNumber = Double(yearsExp) ?? 0.0
        
        // Rebuild the plan_data with proper types
        let planData: [String: Any] = [
            "route": userInputData["route"] ?? "",
            "grade": userInputData["grade"] ?? "",
            "crag": userInputData["crag"] ?? "",
            "route_angles": userInputData["route_angles"] ?? "",
            "route_lengths": userInputData["route_lengths"] ?? "",
            "hold_types": userInputData["hold_types"] ?? "",
            "route_style": userInputData["route_style"] ?? "",
            "route_description": userInputData["route_description"] ?? "",
            "weeks_to_train": userInputData["weeks_to_train"] ?? "8",
            "sessions_per_week": userInputData["sessions_per_week"] ?? "4",
            "time_per_session": userInputData["time_per_session"] ?? "2",
            "current_climbing_grade": userInputData["current_climbing_grade"] ?? "",
            "max_boulder_grade": userInputData["max_boulder_grade"] ?? "",
            "training_experience": userInputData["training_experience"] ?? "",
            "perceived_strengths": userInputData["perceived_strengths"] ?? "",
            "perceived_weaknesses": userInputData["perceived_weaknesses"] ?? "",
            "attribute_ratings": userInputData["attribute_ratings"] ?? "",
            "training_facilities": userInputData["training_facilities"] ?? "",
            "injury_history": userInputData["injury_history"] ?? "",
            "general_fitness": userInputData["general_fitness"] ?? "",
            "height": userInputData["height"] ?? "",
            "weight": userInputData["weight"] ?? "",
            "age": userInputData["age"]?.components(separatedBy: " ").first ?? "30",
            "years_experience": yearsNumber,
            "preferred_climbing_style": userInputData["preferred_climbing_style"] ?? "",
            "indoor_vs_outdoor": userInputData["indoor_vs_outdoor"] ?? "",
            "onsight_flash_level": userInputData["onsight_flash_level"] ?? "",
            "redpointing_experience": userInputData["redpointing_experience"] ?? "",
            "sleep_recovery": userInputData["sleep_recovery"] ?? "",
            "work_life_balance": userInputData["work_life_balance"] ?? "",
            "fear_factors": userInputData["fear_factors"] ?? "",
            "mindfulness_practices": userInputData["mindfulness_practices"] ?? "",
            "motivation_level": userInputData["motivation_level"] ?? "",
            "access_to_coaches": userInputData["access_to_coaches"] ?? "",
            "time_for_cross_training": userInputData["time_for_cross_training"] ?? "",
            "additional_notes": userInputData["additional_notes"] ?? ""
        ]
        
        // Create a full plan request structure
        let fullPlanRequest: [String: Any] = [
            "plan_data": planData,
            "weeks_to_train": weeksToTrain,
            "sessions_per_week": sessionsPerWeek,
            "previous_analysis": """
    Route Overview: \(previewData.routeOverview)
    
    Training Approach: \(previewData.trainingApproach)
    """
        ]
        
        // Use the ASYNC endpoint instead
        guard let url = URL(string: "\(baseURL)/training_plans/generate_full") else {
            self.isPurchasing = false
            self.purchaseError = "Invalid URL for full plan generation."
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addAuthHeader()
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: fullPlanRequest) else {
            self.isPurchasing = false
            self.purchaseError = "Failed to serialize request data."
            return
        }
        
        // Debug print to see what we're sending
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 Full request payload:")
            print(jsonString)
        }
        
        request.httpBody = jsonData
        
        // Use async/await with our URLSession.authenticatedData(for:)
        Task {
            do {
                // If addAuthHeader might change token, do it on main actor (safety)
                var req = request
                await MainActor.run { req.addAuthHeader() }
                
                let (data, response) = try await URLSession.shared.authenticatedData(for: req)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run {
                        self.purchaseError = "Invalid response"
                        self.isPurchasing = false
                    }
                    return
                }
                
                // Log response for debugging
                print("📥 Response status: \(httpResponse.statusCode)")
                if let bodyString = String(data: data, encoding: .utf8) {
                    print("📥 Response body: \(bodyString)")
                }
                
                guard httpResponse.statusCode == 200 else {
                    // Try to decode your error shape; if not available, show status code
                    let serverMsg: String
                    if let err = try? JSONDecoder().decode(ServerError.self, from: data) {
                        serverMsg = err.detail
                    } else if let txt = String(data: data, encoding: .utf8) {
                        serverMsg = "Server error (\(httpResponse.statusCode)): \(txt)"
                    } else {
                        serverMsg = "Server error: \(httpResponse.statusCode)"
                    }
                    await MainActor.run {
                        self.purchaseError = serverMsg
                        self.isPurchasing = false
                    }
                    return
                }
                
                // Decode the plan and finish
                let phasePlan = try JSONDecoder().decode(PlanConverter.PhaseBasedPlan.self, from: data)
                let finalPlan = PlanConverter.convertToUIModel(
                    phasePlan: phasePlan,
                    routeName: self.routeName,
                    grade: self.grade,
                    previewRouteOverview: self.previewData.routeOverview,
                    previewTrainingOverview: self.previewData.trainingApproach
                )
                
                await MainActor.run {
                    self.onPurchaseComplete(finalPlan)
                    self.isPurchasing = false
                    self.dismiss()
                }
            } catch {
                await MainActor.run {
                    self.purchaseError = "Network error: \(error.localizedDescription)"
                    self.isPurchasing = false
                }
            }
        }
    }

    // Add polling method to PlanPreviewView
    private func pollForPlanCompletion(taskId: String) {
        guard let url = URL(string: "\(baseURL)/training_plans/plan_status/\(taskId)") else {
            self.purchaseError = "Invalid status URL"
            self.isPurchasing = false
            return
        }
        
        var request = URLRequest(url: url)
        request.addAuthHeader()
        
        Task {
            do {
                var req = request
                await MainActor.run { req.addAuthHeader() }
                
                let (data, response) = try await URLSession.shared.authenticatedData(for: req)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    await MainActor.run {
                        self.purchaseError = "Invalid response"
                        self.isPurchasing = false
                    }
                    return
                }
                
                print("📥 Status check response code: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    let serverMsg: String
                    if let txt = String(data: data, encoding: .utf8) {
                        serverMsg = "Server error during plan generation: \(txt)"
                    } else {
                        serverMsg = "Server error during plan generation. Please try again."
                    }
                    await MainActor.run {
                        self.purchaseError = serverMsg
                        self.isPurchasing = false
                    }
                    return
                }
                
                // Log the raw response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 Status response: \(responseString)")
                }
                
                let status = try JSONDecoder().decode(StatusResponse.self, from: data)
                
                switch status.status {
                case "processing":
                    if let progress = status.progress {
                        await MainActor.run {
                            self.currentGenerationStep = min(5, Int(progress / 20.0) + 1)
                        }
                    }
                    // Poll again after 2s
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    self.pollForPlanCompletion(taskId: taskId)
                    
                case "complete":
                    if let plan = status.plan {
                        let finalPlan = PlanConverter.convertToUIModel(
                            phasePlan: plan,
                            routeName: self.routeName,
                            grade: self.grade,
                            previewRouteOverview: self.previewData.routeOverview,
                            previewTrainingOverview: self.previewData.trainingApproach
                        )
                        await MainActor.run {
                            self.onPurchaseComplete(finalPlan)
                            self.dismiss()
                            self.isPurchasing = false
                        }
                    } else {
                        await MainActor.run {
                            self.purchaseError = "No plan data received"
                            self.isPurchasing = false
                        }
                    }
                    
                case "error":
                    await MainActor.run {
                        self.purchaseError = status.message ?? "Generation failed"
                        self.isPurchasing = false
                    }
                    
                default:
                    await MainActor.run {
                        self.purchaseError = "Unknown status: \(status.status)"
                        self.isPurchasing = false
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.purchaseError = "Network error: \(error.localizedDescription)"
                    self.isPurchasing = false
                }
            }
        }
    }

    // Add the status response model
    struct StatusResponse: Decodable {
        let status: String
        let progress: Double?
        let plan: PlanConverter.PhaseBasedPlan?
        let message: String?
    }
    
    // Helper view for feature rows
    struct FeatureRow: View {
        let icon: String
        let text: String
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.ascendGreen)
                    .font(.system(size: 16))
                    .frame(width: 24, height: 24)
                
                Text(text)
                    .foregroundColor(.primary)
            }
        }
    }
    
    // Preview helper
    struct PlanPreviewView_Previews: PreviewProvider {
        static var previews: some View {
            PlanPreviewView(
                routeName: "Example Route",
                grade: "7a+",
                previewData: PlanPreviewData(
                    routeOverview: "This is an example route overview that describes the key features of the climb.",
                    trainingApproach: "The training approach will focus on building finger strength, power endurance, and technique for steep crimpy limestone routes."
                ),
                userInputData: [:],
                onPurchaseComplete: { _ in }
            )
        }
    }
}
