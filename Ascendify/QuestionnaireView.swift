//
//  QuestionnaireView.swift
//  Ascendify
//
//  Created by Ellis Barker on 09/02/2025.
//

import SwiftUI

// ======================================================
// MARK: – Data Models & Constants (Top Level, File Scope)

/// A single rated attribute (strength/weakness) on a 1–5 scale
struct RatedAttribute: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var rating: Int // 1–5 scale
}

/// A single “trainingFacilities” option
struct TrainingFacilitiesOption: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: String
}

/// A single “generalFitness” option
struct GeneralFitnessOption: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: String
}

/// A single “climbing style” option for multi‐select
struct ClimbingStyleOption: Identifiable, Hashable {
    let id = UUID()
    let name: String
}

// List of attributes to rate on a 1–5 scale
let attributesToRate = [
    "Crimp Strength",
    "Pinch Strength",
    "Pocket Strength",
    "Strength",
    "Power",
    "Power Endurance",
    "Endurance",
    "Upper Body Strength",
    "Core Strength",
    "Flexibility",
    "Mental Strength"
]

// === Helper: turn "Crimp Strength: 4, Pinch Strength: 5, ..." -> ["Crimp Strength":4, ...]
private func parseAttributeRatings(_ s: String) -> [String:Int] {
    var out: [String:Int] = [:]
    for part in s.split(separator: ",") {
        let bits = part.split(separator: ":", maxSplits: 1)
        guard bits.count == 2 else { continue }
        let key = bits[0].trimmingCharacters(in: .whitespaces)
        let val = bits[1].trimmingCharacters(in: .whitespaces)
        if let n = Int(val) { out[key] = n }
    }
    return out
}


// MARK: – Data for Facilities

/// All available training facilities, each with a “category” string
let allTrainingFacilitiesOptions: [TrainingFacilitiesOption] = [
    // Indoor Wall
    TrainingFacilitiesOption(name: "Lead Wall", category: "Indoor Wall"),
    TrainingFacilitiesOption(name: "Bouldering Wall", category: "Indoor Wall"),
    TrainingFacilitiesOption(name: "Climbing Board", category: "Indoor Wall"),
    TrainingFacilitiesOption(name: "Spray Wall", category: "Indoor Wall"),
    TrainingFacilitiesOption(name: "Circuit Board", category: "Indoor Wall"),
    TrainingFacilitiesOption(name: "Fingerboard", category: "Indoor Wall"),
    TrainingFacilitiesOption(name: "Campus Board", category: "Indoor Wall"),
    TrainingFacilitiesOption(name: "Pull-up Bar", category: "Indoor Wall"),
    TrainingFacilitiesOption(name: "Weights", category: "Indoor Wall"),
    // Home
    TrainingFacilitiesOption(name: "Fingerboard", category: "Home"),
    TrainingFacilitiesOption(name: "Climbing Board", category: "Home"),
    TrainingFacilitiesOption(name: "Weights", category: "Home")
]

// MARK: – Data for General Fitness

let allGeneralFitnessOptions: [GeneralFitnessOption] = [
    GeneralFitnessOption(name: "Excellent", category: "Fitness Level"),
    GeneralFitnessOption(name: "Good", category: "Fitness Level"),
    GeneralFitnessOption(name: "Average", category: "Fitness Level"),
    GeneralFitnessOption(name: "Below Average", category: "Fitness Level"),
    GeneralFitnessOption(name: "Very Poor", category: "Fitness Level")
]

// MARK: – Data for Climbing Styles

let allClimbingStyleOptions: [ClimbingStyleOption] = [
    ClimbingStyleOption(name: "Slab"),
    ClimbingStyleOption(name: "Overhanging"),
    ClimbingStyleOption(name: "Roof"),
    ClimbingStyleOption(name: "Vertical"),
    ClimbingStyleOption(name: "Crimpy"),
    ClimbingStyleOption(name: "Slopers"),
    ClimbingStyleOption(name: "Pinches"),
    ClimbingStyleOption(name: "Long"),
    ClimbingStyleOption(name: "Short"),
    ClimbingStyleOption(name: "Bouldery")
]

// MARK: – Single-Choice Menus (for various pickers)

let redpointingMenu       = ["None", "Low", "Medium", "High", "A lot"]
let workLifeBalanceMenu   = ["Physically Demanding", "Somewhat Physical", "Mostly Desk", "Flexible/None"]
let motivationMenu        = ["Low", "Medium", "High", "Very High"]
let yesNoMenu             = ["No", "Yes"]
let crossTrainingMenu     = (1...10).map { "\($0)h per week" }

// For numeric wheel pickers
let heightRange = (100...210).map { "\($0) cm" }
let weightRange = (30...120).map { "\($0) kg" }
let ageRange    = (10...80).map { "\($0) yrs" }

// ======================================================
// MARK: – Common “Chip” Styles

/// A reusable “chip” that shows a title with an optional checkmark,
/// toggles on/off when tapped, and styles itself accordingly. Used in grids.
struct ToggleChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .transition(.opacity)
                }
                Text(title)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? color.opacity(0.3) : Color.gray.opacity(0.15))
            .foregroundColor(isSelected ? color : .primary)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isSelected ? color.opacity(0.8) : Color.gray.opacity(0.2), lineWidth: 1.2)
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// A single‐select “chip” style (dynamic width based on content). Used for Work Life Balance.
struct SingleSelectChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color(.systemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isSelected ? color.opacity(0.9) : Color.gray.opacity(0.2), lineWidth: 1.2)
                )
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// ======================================================
// MARK: – FacilityCategoryView (Padded Label + Rotating Chevron)

/// A single category (e.g. “Home” or “Indoor Wall”) shown as a
/// DisclosureGroup whose label is inset from the edges, and whose
/// chevron rotates when expanded.
struct FacilityCategoryView: View {
    let category: String
    let items: [TrainingFacilitiesOption]
    @Binding var selectedFacilities: [TrainingFacilitiesOption]

    @State private var isExpanded: Bool = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            // Grid of facility chips
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 10) {
                ForEach(items) { item in
                    ToggleChip(
                        title: item.name,
                        isSelected: selectedFacilities.contains(item),
                        color: .green
                    ) {
                        if selectedFacilities.contains(item) {
                            selectedFacilities.removeAll { $0 == item }
                        } else {
                            selectedFacilities.append(item)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
        } label: {
            // Custom label: category text + rotating chevron
            HStack {
                Text(category)
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .tint(.clear) // hide built-in arrow
    }
}

// ======================================================
// MARK: – FacilitiesGridView (Entire “Training Facilities” Section)

/// A vertical list of categories; each category expands to show
/// a grid of facility chips. Uses FacilityCategoryView for each row.
struct FacilitiesGridView: View {
    @Binding var selectedFacilities: [TrainingFacilitiesOption]

    /// Group all facility options by category
    private var facilitiesByCategory: [String: [TrainingFacilitiesOption]] {
        Dictionary(grouping: allTrainingFacilitiesOptions, by: \.category)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ForEach(facilitiesByCategory.keys.sorted(), id: \.self) { category in
                FacilityCategoryView(
                    category: category,
                    items: facilitiesByCategory[category] ?? [],
                    // <<< Use the local binding name “selectedFacilities” here
                    selectedFacilities: $selectedFacilities
                )
            }
        }
    }
}

// ======================================================
// MARK: – FitnessLevelView (Now matches Motivation style)

/// A single‐select grid for general fitness levels (“Excellent,” “Good,” etc.)
struct FitnessLevelView: View {
    @Binding var selectedFitness: [GeneralFitnessOption]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 10) {
            ForEach(allGeneralFitnessOptions) { item in
                ToggleChip(
                    title: item.name,
                    isSelected: selectedFitness.contains(item),
                    color: .purple
                ) {
                    // Single‐select behavior
                    selectedFitness.removeAll()
                    selectedFitness.append(item)
                }
            }
        }
        .padding(.all, 8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// ======================================================
// MARK: – ClimbingStylesGridView (with horizontal padding)

/// A multi‐select grid for preferred climbing styles (“Slab,” “Roof,” etc.)
struct ClimbingStylesGridView: View {
    @Binding var selectedStyles: [ClimbingStyleOption]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
            ForEach(allClimbingStyleOptions) { item in
                ToggleChip(
                    title: item.name,
                    isSelected: selectedStyles.contains(item),
                    color: .orange
                ) {
                    if selectedStyles.contains(item) {
                        selectedStyles.removeAll { $0 == item }
                    } else {
                        selectedStyles.append(item)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// ======================================================
// MARK: – Main QuestionnaireView

struct QuestionnaireView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss

    // Current page state
    @State private var currentPage = 0
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    // MARK: – Section 1: Personal Information

    @State private var name = ""
    @State private var email = ""
    @State private var height = "170 cm"
    @State private var weight = "70 kg"
    @State private var age = "30 yrs"

    // MARK: – Section 2: Climbing Experience

    @State private var currentClimbingGrade = ""
    @State private var maxBoulderGrade = ""
    @State private var goal = ""
    @State private var trainingExperienceYears = 0 
    @State private var indoorVsOutdoor = ""
    @State private var redpointingExperience = "None"

    // MARK: – Section 3: Strengths & Weaknesses & Styles

    @State private var ratedAttributes: [RatedAttribute] = attributesToRate.map {
        RatedAttribute(name: $0, rating: 3) // Default rating = 3
    }
    @State private var selectedClimbingStyles: [ClimbingStyleOption] = []

    // MARK: – Section 4: Training Setup

    @State private var selectedTrainingFacilities: [TrainingFacilitiesOption] = []
    @State private var injuryHistory = ""

    // MARK: – Section 5: Health & Recovery

    @State private var selectedGeneralFitness: [GeneralFitnessOption] = []
    @State private var selectedSleepHour = "8"
    @State private var workLifeBalance = "Mostly Desk"
    @State private var motivationLevel = "High"

    // Hours array 4–12 for sleep scroller
    private let sleepHours = (4...12).map { "\($0)" }

    // MARK: – Section 6: Additional Information

    @State private var accessToCoaches = "No"
    @State private var crossTrainingTime = "3h per week"
    @State private var additionalNotes = ""

    // Array of section titles
    private let sectionTitles = [
        "Personal Info",
        "Climbing Experience",
        "Abilities & Style",
        "Training Setup",
        "Health & Recovery",
        "Additional Info"
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.deepPurple.opacity(0.1),
                    Color.ascendGreen.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HeaderView()
                
                HStack {
                    Spacer()
                    Button("Complete later in Settings") {
                        // keep needsQuestionnaire = true, just stop auto-presenting the sheet
                        userViewModel.setShowQuestionnairePrompt(false)
                        dismiss()
                    }
                    .font(.footnote)
                    .foregroundColor(.tealBlue)
                    .padding(.trailing, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                }
                
                // Title + page count
                HStack {
                    Text("Questionnaire")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.deepPurple)
                    
                    Spacer()
                    
                    Text("\(currentPage + 1)/\(sectionTitles.count)")
                        .foregroundColor(.tealBlue)
                        .fontWeight(.medium)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Progress indicators (enhanced)
                HStack(spacing: 5) {
                    ForEach(0..<sectionTitles.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage >= index ? Color.ascendGreen : Color.gray.opacity(0.2))
                            .frame(height: 6)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
                
                // MARK: – TabView for Sections 1–6
                TabView(selection: $currentPage) {
                    // ------------------------------
                    // Section 1: Personal Information
                    // ------------------------------
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            SectionHeader(title: "Personal Information", icon: "person.fill")
                            
                            TextField("Full Name", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal, 0)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            
                            TextField("Email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .disabled(true)
                                .opacity(0.7)
                                .padding(.horizontal, 0)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            
                            Group {
                                Text("Height")
                                    .font(.headline)
                                
                                Picker("Height", selection: $height) {
                                    ForEach(heightRange, id: \.self) { h in
                                        Text(h).tag(h)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 100)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                
                                Text("Weight")
                                    .font(.headline)
                                
                                Picker("Weight", selection: $weight) {
                                    ForEach(weightRange, id: \.self) { w in
                                        Text(w).tag(w)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 100)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                
                                Text("Age")
                                    .font(.headline)
                                
                                Picker("Age", selection: $age) {
                                    ForEach(ageRange, id: \.self) { a in
                                        Text(a).tag(a)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 100)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            }
                            
                            NavigationButton(
                                currentPage: $currentPage,
                                maxPage: sectionTitles.count,
                                isForward: true,
                                disabled: !isSection1Valid
                            )
                        }
                        .padding()
                    }
                    .tag(0)
                    
                    // ------------------------------
                    // Section 2: Climbing Experience
                    // ------------------------------
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            SectionHeader(title: "Climbing Experience", icon: "figure.climbing")
                            
                            Group {
                                Text("Current Climbing Grade")
                                    .font(.headline)
                                
                                TextField("e.g. 7a, 5.12a", text: $currentClimbingGrade)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                
                                Text("Max Boulder Grade")
                                    .font(.headline)
                                
                                TextField("e.g. V5, 6C+", text: $maxBoulderGrade)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                
                                Text("Grade Goal")
                                    .font(.headline)
                                
                                TextField("e.g. 7c+, 5.13a", text: $goal)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            }
                            
                            Group {
                                Text("Years of Structured Training")
                                    .font(.headline)

                                Picker("Years", selection: $trainingExperienceYears) {
                                    ForEach(0...40, id: \.self) { y in
                                        Text("\(y) year\(y == 1 ? "" : "s")").tag(y)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 120) // was 100
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                                Text("Indoor vs Outdoor Preference")
                                    .font(.headline)

                                TextEditor(text: $indoorVsOutdoor)
                                    .frame(height: 80)
                                    .padding(8)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )

                                Text("Redpointing Experience")
                                    .font(.headline)

                                Picker("Level", selection: $redpointingExperience) {
                                    ForEach(redpointingMenu, id: \.self) { level in
                                        Text(level).tag(level)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.vertical, 6)
                            }
                            NavigationButtonGroup(currentPage: $currentPage, maxPage: sectionTitles.count)
                        }
                        .padding()
                    }
                    .tag(1)
                    
                    // ----------------------------
                    // Section 3: Abilities & Style
                    // ----------------------------
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            SectionHeader(title: "Abilities Rating", icon: "chart.bar.fill")
                            
                            Text("Rate your abilities from 1 (weakness) to 5 (strength)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.bottom, 10)
                            
                            ForEach(ratedAttributes.indices, id: \.self) { index in
                                AttributeRatingView(
                                    attribute: ratedAttributes[index].name,
                                    rating: $ratedAttributes[index].rating
                                )
                            }
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Preferred Climbing Styles")
                                    .font(.headline)
                                    .padding(.top, 20)
                                
                                ClimbingStylesGridView(selectedStyles: $selectedClimbingStyles)
                            }
                            .padding(.bottom, 20)
                            
                            NavigationButtonGroup(currentPage: $currentPage, maxPage: sectionTitles.count)
                        }
                        .padding()
                    }
                    .tag(2)
                    
                    // ------------------------
                    // Section 4: Training Setup
                    // ------------------------
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            SectionHeader(title: "Training Setup", icon: "calendar")
                            
                            // Training Facilities
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Training Facilities")
                                    .font(.headline)
                                
                                FacilitiesGridView(selectedFacilities: $selectedTrainingFacilities)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 8)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            .padding(.bottom, 20)
                            
                            // Injury History
                            Group {
                                Text("Injury History")
                                    .font(.headline)
                                
                                TextEditor(text: $injuryHistory)
                                    .frame(height: 120)
                                    .padding(4)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            NavigationButtonGroup(currentPage: $currentPage, maxPage: sectionTitles.count)
                        }
                        .padding()
                    }
                    .tag(3)
                    
                    // ----------------------------
                    // Section 5: Health & Recovery
                    // ----------------------------
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            SectionHeader(title: "Health & Recovery", icon: "heart.fill")
                            
                            // === General Fitness Level ===
                            VStack(alignment: .leading, spacing: 8) {
                                Text("General Fitness Level")
                                    .font(.headline)
                                
                                FitnessLevelView(selectedFitness: $selectedGeneralFitness)
                            }
                            
                            // === Sleep Recovery (avg hours) ===
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sleep Recovery (avg hours)")
                                    .font(.headline)
                                
                                // Card-style horizontal scroller of hour chips
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(sleepHours, id: \.self) { h in
                                            Button(action: {
                                                selectedSleepHour = h
                                            }) {
                                                Text(h)
                                                    .font(.headline)
                                                    .frame(width: 50, height: 50)
                                                    .background(
                                                        selectedSleepHour == h
                                                        ? Color.ascendGreen
                                                        : Color(.systemBackground)
                                                    )
                                                    .foregroundColor(
                                                        selectedSleepHour == h
                                                        ? .white
                                                        : .primary
                                                    )
                                                    .cornerRadius(12)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                    )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                }
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            }
                            
                            // === Work Life Balance ===
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Work Life Balance")
                                    .font(.headline)
                                
                                // Card-style horizontal scroller of work-life chips
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(workLifeBalanceMenu, id: \.self) { option in
                                            SingleSelectChip(
                                                title: option,
                                                isSelected: workLifeBalance == option,
                                                color: .tealBlue
                                            ) {
                                                workLifeBalance = option
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                }
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            }
                            
                            // === Motivation Level ===
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Motivation Level")
                                    .font(.headline)
                                
                                // Card-style container for segmented picker
                                Picker("Motivation", selection: $motivationLevel) {
                                    ForEach(motivationMenu, id: \.self) { m in
                                        Text(m).tag(m)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.all, 8)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            }
                            
                            // Navigation for Section 5
                            NavigationButtonGroup(currentPage: $currentPage, maxPage: sectionTitles.count)
                                .padding(.top, 16)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                    .tag(4)
                    
                    // -------------------------------
                    // Section 6: Additional Information
                    // -------------------------------
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            SectionHeader(title: "Additional Information", icon: "info.circle.fill")
                            
                            Group {
                                Text("Access to Coaches")
                                    .font(.headline)
                                
                                Picker("Access to Coaches", selection: $accessToCoaches) {
                                    ForEach(yesNoMenu, id: \.self) { ans in
                                        Text(ans).tag(ans)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.all, 8)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                .padding(.bottom, 20)
                                
                                Text("Time for Cross Training")
                                    .font(.headline)
                                
                                Picker("Time for Cross Training", selection: $crossTrainingTime) {
                                    ForEach(crossTrainingMenu, id: \.self) { ct in
                                        Text(ct).tag(ct)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(height: 100)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                
                                Text("Additional Notes")
                                    .font(.headline)
                                
                                TextEditor(text: $additionalNotes)
                                    .frame(height: 120)
                                    .padding(4)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            if let error = errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .padding(.vertical, 8)
                            }
                            
                            Button(action: submitQuestionnaire) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.ascendGreen.opacity(0.7))
                                        .cornerRadius(12)
                                } else {
                                    Text("Submit Questionnaire")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(isSubmitEnabled ? Color.ascendGreen : Color.gray.opacity(0.6))
                                        .cornerRadius(12)
                                }
                            }
                            .disabled(!isSubmitEnabled)
                            .padding(.vertical)
                            
                            NavigationButton(
                                currentPage: $currentPage,
                                maxPage: sectionTitles.count,
                                isForward: false
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                    .tag(5)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                .transition(.slide)
            }
        }
        .onAppear(perform: {
            // Force reload profile before loading existing data
            if let email = userViewModel.userProfile?.email {
                userViewModel.fetchUserProfile(email: email) { _ in
                    loadExistingData()
                }
            } else {
                loadExistingData()
            }
        })
    }

    // MARK: – Validation for Section 1
    private var isSection1Valid: Bool {
        return !name.isEmpty && !email.isEmpty
    }

    // MARK: – Data Loading & Submission

    private func loadExistingData() {
        print("🔍 loadExistingData called")
        print("🔍 userViewModel.userProfile: \(userViewModel.userProfile)")
        
        if let profile = userViewModel.userProfile {
            name = profile.name

            if let profileEmail = profile.email {
                email = profileEmail
            } else {
                email = ""
            }

            currentClimbingGrade = profile.currentClimbingGrade
            maxBoulderGrade = profile.maxBoulderGrade
            goal = profile.goal
            let digitsOnly = profile.trainingExperience.filter { $0.isNumber }
            trainingExperienceYears = Int(digitsOnly) ?? 0


            // Legacy support: Populate ratedAttributes from perceived strengths/weaknesses
            // Prefer exact numeric ratings if present; otherwise fall back to legacy strengths/weaknesses.
            if !profile.attribute_ratings.isEmpty {
                let dict = parseAttributeRatings(profile.attribute_ratings)
                for i in ratedAttributes.indices {
                    let key = ratedAttributes[i].name
                    if let v = dict[key] {
                        ratedAttributes[i].rating = max(1, min(5, v))
                    }
                }
            } else if !profile.perceivedStrengths.isEmpty || !profile.perceivedWeaknesses.isEmpty {
                // Legacy fallback
                let oldStrengths = profile
                    .perceivedStrengths
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                let oldWeaknesses = profile
                    .perceivedWeaknesses
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }

                for i in 0..<ratedAttributes.count {
                    let name = ratedAttributes[i].name
                    if oldStrengths.contains(name) {
                        ratedAttributes[i].rating = 4
                    } else if oldWeaknesses.contains(name) {
                        ratedAttributes[i].rating = 2
                    } else {
                        ratedAttributes[i].rating = 3
                    }
                }
            }


            let oldFacilities = profile.trainingFacilities
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            selectedTrainingFacilities = allTrainingFacilitiesOptions
                .filter { oldFacilities.contains($0.name) }

            let oldFitness = profile.generalFitness
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            selectedGeneralFitness = allGeneralFitnessOptions
                .filter { oldFitness.contains($0.name) }

            injuryHistory = profile.injuryHistory

            height = profile.height.isEmpty ? "170 cm" : profile.height
            weight = profile.weight.isEmpty ? "70 kg" : profile.weight
            age = profile.age.isEmpty ? "30 yrs" : profile.age

            let oldStyles = profile.preferredClimbingStyle
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            selectedClimbingStyles = allClimbingStyleOptions
                .filter { oldStyles.contains($0.name) }

            indoorVsOutdoor = profile.indoorVsOutdoor
            redpointingExperience = profile.redpointingExperience.isEmpty ? "None" : profile.redpointingExperience

            // For sleep, if the stored value is “8 hours”, split out just “8”
            if !profile.sleepRecovery.isEmpty {
                let parts = profile.sleepRecovery.split(separator: " ")
                if let first = parts.first {
                    selectedSleepHour = String(first)
                }
            }

            workLifeBalance = profile.workLifeBalance.isEmpty ? "Mostly Desk" : profile.workLifeBalance
            motivationLevel = profile.motivationLevel.isEmpty ? "High" : profile.motivationLevel
            accessToCoaches = profile.accessToCoaches.isEmpty ? "No" : profile.accessToCoaches
            crossTrainingTime = profile.timeForCrossTraining.isEmpty ? "3h per week" : profile.timeForCrossTraining
            additionalNotes = profile.additionalNotes
        }
    }

    private func submitQuestionnaire() {
        isLoading = true
        errorMessage = nil

        guard let email = userViewModel.userProfile?.email else {
            errorMessage = "No user email found."
            isLoading = false
            return
        }

        // Convert rated attributes to a string format
        let attributeRatings = ratedAttributes
            .map { "\($0.name): \($0.rating)" }
            .joined(separator: ", ")

        // Extract strengths and weaknesses for backward compatibility
        let strengths = ratedAttributes.filter { $0.rating >= 4 }.map { $0.name }
        let weaknesses = ratedAttributes.filter { $0.rating <= 2 }.map { $0.name }
        let strengthString = strengths.joined(separator: ", ")
        let weaknessString = weaknesses.joined(separator: ", ")

        // Other multi-selects
        let facilitiesString = selectedTrainingFacilities.map { $0.name }.joined(separator: ", ")
        let fitnessString = selectedGeneralFitness.map { $0.name }.joined(separator: ", ")
        let styleString = selectedClimbingStyles.map { $0.name }.joined(separator: ", ")

        // Convert selectedSleepHour (e.g. "8") → "8 hours"
        let sleepString = "\(selectedSleepHour) hours"

        let answers: [String: String] = [
            "name": name,
            "email": email,
            "current_climbing_grade": currentClimbingGrade,
            "max_boulder_grade": maxBoulderGrade,
            "goal": goal,
            "training_experience": String(trainingExperienceYears),

            // Backward-compatibility fields
            "perceived_strengths": strengthString,
            "perceived_weaknesses": weaknessString,
            "attribute_ratings": attributeRatings,

            "training_facilities": facilitiesString,
            "general_fitness": fitnessString,
            "injury_history": injuryHistory,

            "height": height,
            "weight": weight,
            "age": age,

            "preferred_climbing_style": styleString,
            "indoor_vs_outdoor": indoorVsOutdoor,
            "redpointing_experience": redpointingExperience,
            "sleep_recovery": sleepString,
            "work_life_balance": workLifeBalance,
            "motivation_level": motivationLevel,
            "access_to_coaches": accessToCoaches,
            "time_for_cross_training": crossTrainingTime,

            "additional_notes": additionalNotes
        ]

        userViewModel.submitQuestionnaireAnswers(answers) { success in
            isLoading = false
            if success {
                if var profile = userViewModel.userProfile {
                    profile.name = name
                    profile.currentClimbingGrade = currentClimbingGrade
                    profile.maxBoulderGrade = maxBoulderGrade
                    profile.goal = goal
                    profile.trainingExperience = String(trainingExperienceYears)
                    profile.perceivedStrengths = strengthString
                    profile.perceivedWeaknesses = weaknessString
                    profile.attribute_ratings = attributeRatings

                    profile.trainingFacilities = facilitiesString
                    profile.generalFitness = fitnessString
                    profile.injuryHistory = injuryHistory
                    profile.height = height
                    profile.weight = weight
                    profile.age = age
                    profile.preferredClimbingStyle = styleString
                    profile.indoorVsOutdoor = indoorVsOutdoor
                    profile.redpointingExperience = redpointingExperience
                    profile.sleepRecovery = sleepString
                    profile.workLifeBalance = workLifeBalance
                    profile.motivationLevel = motivationLevel
                    profile.accessToCoaches = accessToCoaches
                    profile.timeForCrossTraining = crossTrainingTime
                    profile.additionalNotes = additionalNotes

                    userViewModel.userProfile = profile
                }

                userViewModel.needsQuestionnaire = false
                userViewModel.setShowQuestionnairePrompt(false)
                dismiss()
            } else {
                errorMessage = "Failed to save questionnaire. Please try again."
            }
        }
    }

    // ======================================================
    // MARK: – Helper Subviews (Still inside QuestionnaireView)
    
    /// Only save when complete
    private var isSubmitEnabled: Bool {
        !currentClimbingGrade.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !maxBoulderGrade.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isLoading
    }

    /// Enhanced slider view for rating abilities
    struct AttributeRatingView: View {
        let attribute: String
        @Binding var rating: Int

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(attribute)
                    .font(.headline)

                Slider(value: Binding<Double>(
                    get: { Double(rating) },
                    set: { rating = Int(round($0)) }
                ), in: 1...5, step: 1)
                .accentColor(ratingColor(rating))

                HStack {
                    Spacer()
                    Text("Rating: \(rating)/5")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ratingColor(rating))
                    Spacer()
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }

        // Color gradient based on rating
        private func ratingColor(_ value: Int) -> Color {
            switch value {
            case 1: return .red
            case 2: return .orange
            case 3: return .yellow
            case 4: return .green
            case 5: return .blue
            default: return .gray
            }
        }
    }

    /// Section header with an SF-symbol icon
    struct SectionHeader: View {
        let title: String
        let icon: String

        var body: some View {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.ascendGreen)

                Text(title)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.deepPurple)
            }
            .padding(.bottom, 8)
        }
    }

    /// Enhanced “Back” or “Next” button
    struct NavigationButton: View {
        @Binding var currentPage: Int
        let maxPage: Int
        let isForward: Bool
        var disabled: Bool = false

        var body: some View {
            Button(action: {
                withAnimation {
                    currentPage += isForward ? 1 : -1
                }
            }) {
                HStack {
                    if !isForward { Image(systemName: "arrow.left") }
                    Text(isForward ? "Next" : "Back")
                        .fontWeight(.bold)
                    if isForward { Image(systemName: "arrow.right") }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(disabled ? Color.gray.opacity(0.6) : (isForward ? Color.ascendGreen : Color.tealBlue))
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
            }
            .disabled(disabled)
        }
    }

    /// A pair of “Back” + “Next” buttons side by side
    struct NavigationButtonGroup: View {
        @Binding var currentPage: Int
        let maxPage: Int

        var body: some View {
            HStack(spacing: 15) {
                NavigationButton(
                    currentPage: $currentPage,
                    maxPage: maxPage,
                    isForward: false
                )
                NavigationButton(
                    currentPage: $currentPage,
                    maxPage: maxPage,
                    isForward: true
                )
            }
        }
    }

    // ======================================================
    // MARK: – Preview

    struct QuestionnaireView_Previews: PreviewProvider {
        static var previews: some View {
            QuestionnaireView()
                .environmentObject(UserViewModel())
        }
    }
}
