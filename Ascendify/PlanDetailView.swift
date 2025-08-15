//
//  PlanDetailView.swift
//  Ascendify
//
//  Created by Ellis Barker on 17/03/2025.
//

import SwiftUI

// MARK: - Main Plan Detail View
struct PlanDetailView: View {
    let plan: PlanModel
    let routeName: String
    let grade: String
    let planId: String
    
    init(plan: PlanModel,
             routeName: String? = nil,
             grade: String? = nil,
             planId: String? = nil) {
            self.plan = plan
            // Keep existing logic for routeName/grade defaults
            self.routeName = routeName ?? Self.extractRouteName(from: plan.routeOverview)
            self.grade = grade ?? ""
            // Use server planId if provided; otherwise build the slug as before
            if let id = planId {
                self.planId = id.lowercased()
            } else {
                self.planId = "\(self.routeName)_\(self.grade)"
                    .replacingOccurrences(of: " ", with: "_")
                    .lowercased()
            }
        }

    @Environment(\.dismiss) private var dismiss
    @State private var selectedExercise: PlanExercise?
    @State private var showingExerciseDetail = false
    @State private var expandedWeeks: Set<Int> = []
    @State private var expandedSessions: Set<UUID> = []
    @State private var showLibraryExercise = false
    @State private var matchingLibraryExercise: (Exercise, ExerciseCategory)?
    @State private var showingFullPlanInfo = false
    @State private var showExpandedView = false
    @ObservedObject private var trackingManager = SessionTrackingManager.shared
    
    // Define progress stats
    private var progressStats: (completed: Int, total: Int, percentage: Double) {
        trackingManager.getCompletionStats(planId: planId)
      }

    private static func extractRouteName(from overview: String) -> String {
        guard
            let afterFor = overview.components(separatedBy: "for ").last,
            let beforeAt = afterFor.components(separatedBy: " at ").first
        else { return "Climbing Route" }
        return beforeAt.components(separatedBy: " (").first ?? beforeAt
    }

    private func extractTotalWeeks() -> Int {
        let maxUpper = plan.weeks
            .compactMap { $0.title.extractWeekRange()?.upperBound }
            .max() ?? 0
        return maxUpper - 1
    }

    private func countTotalSessions() -> Int {
        plan.weeks.reduce(0) { sum, phase in
            let weeksInPhase = phase.title.extractWeekRange()?.count ?? 1
            return sum + (phase.sessions.count * weeksInPhase)
        }
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            PlanDetailHeaderView(
                routeName: routeName,
                grade: grade
            )
            
            if showExpandedView {
                ExpandedPlanDetailView(
                    plan: plan,
                    routeName: routeName,
                    grade: grade,
                    planId: planId
                )
            } else {
                phaseBasedView
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingExerciseDetail, onDismiss: {
            SessionTrackingManager.shared.saveAllData()
        }) {
            if let ex = selectedExercise {
                PlanExerciseDetailView(exercise: ex, routeName: routeName)
            }
        }
        .sheet(isPresented: $showLibraryExercise, onDismiss: {
            SessionTrackingManager.shared.saveAllData()
        }) {
            if let (ex, cat) = matchingLibraryExercise {
                NavigationView {
                    ExerciseDetailView(exercise: ex)
                        .navigationBarTitle(cat.name, displayMode: .inline)
                }
            }
        }
        .onAppear {
            SessionTrackingManager.shared.initializeTrackingForPlan(planId: planId, plan: plan)
        }
        .onDisappear {
            SessionTrackingManager.shared.saveAllData()
        }
    }

    // MARK: - Phase ‑Based View
    private var phaseBasedView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Remove routeHeader from here since DetailHeaderView handles the header
                planSummaryCard

                if showingFullPlanInfo {
                    overviewCards
                    scheduleSection
                }
            }
            .padding(.bottom, 20)
        }
    }

    private var routeHeader: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(routeName) Training Plan")
                .font(.title).bold().foregroundColor(.deepPurple)
            if !grade.isEmpty {
                Text("Grade: \(grade)")
                    .font(.headline).foregroundColor(.tealBlue)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    // In PlanDetailView.swift, update the planSummaryCard computed property:

    private var planSummaryCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Progress circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: progressStats.percentage)
                        .stroke(Color.ascendGreen, style: StrokeStyle(
                            lineWidth: 8, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: progressStats.percentage)
                    
                    VStack(spacing: 2) {
                        Text("\(Int(progressStats.percentage * 100))%")
                            .font(.system(size: 16, weight: .bold))
                        Text("\(progressStats.completed)/\(progressStats.total)")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }

                // Stats labels
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.tealBlue)
                        Text("\(extractTotalWeeks()) weeks")
                            .fontWeight(.medium)
                    }
                    HStack {
                        Image(systemName: "figure.walk")
                            .foregroundColor(.tealBlue)
                        Text("\(countTotalSessions()) sessions")
                            .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)

            // Switch between phase & weekly
            Button {
                withAnimation(.spring()) {
                    showExpandedView.toggle()
                }
            } label: {
                HStack {
                    Text(showExpandedView
                         ? "View Phase Structure"
                         : "View Weekly Schedule")
                    Image(systemName: "arrow.left.arrow.right")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.ascendGreen)
                .cornerRadius(10)
            }

            // Reveal/hide full plan info
            if !showExpandedView {
                Button {
                    withAnimation(.spring()) {
                        showingFullPlanInfo.toggle()
                    }
                } label: {
                    HStack {
                        Text(showingFullPlanInfo
                             ? "Hide Plan Details"
                             : "Show Plan Details")
                        Image(systemName: showingFullPlanInfo
                              ? "chevron.up"
                              : "chevron.down")
                    }
                    .foregroundColor(.tealBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.tealBlue, lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal)
    }

    private var overviewCards: some View {
        VStack(spacing: 16) {
            PlanCardView(title: "Route Overview") {
                Text(plan.routeOverview)
                    .fixedSize(horizontal: false, vertical: true)
            }
            PlanCardView(title: "Training Overview") {
                Text(plan.trainingOverview)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal)
        .transition(.opacity)
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Schedule")
                .font(.title2).bold().foregroundColor(.deepPurple)
                .padding(.horizontal).padding(.top, 10)

            ForEach(plan.weeks.indices, id: \.self) { i in
                WeekView(
                    planId: self.planId,
                    weekIndex: i,
                    week: plan.weeks[i],
                    expandedWeeks: $expandedWeeks,
                    expandedSessions: $expandedSessions,
                    selectedExercise: $selectedExercise,
                    showingExerciseDetail: $showingExerciseDetail,
                    showLibraryExercise: $showLibraryExercise,
                    matchingLibraryExercise: $matchingLibraryExercise
                )
            }
        }
        .transition(.opacity)
    }
}

// MARK: - Week View
struct WeekView: View {
    let planId: String
    let weekIndex: Int
    let week: PlanWeek

    @Binding var expandedWeeks: Set<Int>
    @Binding var expandedSessions: Set<UUID>
    @Binding var selectedExercise: PlanExercise?
    @Binding var showingExerciseDetail: Bool
    @Binding var showLibraryExercise: Bool
    @Binding var matchingLibraryExercise: (Exercise, ExerciseCategory)?

    private var weekRange: Range<Int>? {
        let pattern = "Weeks? (\\d+)-(\\d+)"
        guard
            let regex = try? NSRegularExpression(
                pattern: pattern, options: .caseInsensitive
            ),
            let match = regex.firstMatch(
                in: week.title,
                options: [],
                range: NSRange(week.title.startIndex..<week.title.endIndex,
                               in: week.title)
            ),
            let r1 = Range(match.range(at: 1), in: week.title),
            let r2 = Range(match.range(at: 2), in: week.title),
            let start = Int(week.title[r1]),
            let end = Int(week.title[r2])
        else { return nil }
        return start..<(end + 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.spring()) {
                    // toggle membership by hand:
                    if expandedWeeks.contains(weekIndex) {
                        expandedWeeks.remove(weekIndex)
                    } else {
                        expandedWeeks.insert(weekIndex)
                    }
                }
            } label: {
                HStack {
                    Text(week.title)
                        .font(.headline).foregroundColor(.deepNavy)
                    Spacer()
                    Text("\(week.sessions.count) sessions")
                        .font(.subheadline).foregroundColor(.gray)
                    Image(systemName:
                            expandedWeeks.contains(weekIndex)
                            ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.05), radius: 3)
            }

            if let r = week.title.extractWeekRange() {
                Text("Weeks \(r.lowerBound)-\(r.upperBound - 1)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }

            if expandedWeeks.contains(weekIndex) {
                VStack(spacing: 8) {
                    ForEach(Array(week.sessions.enumerated()), id: \.offset) { _, sess in
                        SessionView(
                            session: sess,
                            expandedSessions: $expandedSessions,
                            selectedExercise: $selectedExercise,
                            showingExerciseDetail: $showingExerciseDetail,
                            showLibraryExercise: $showLibraryExercise,
                            matchingLibraryExercise: $matchingLibraryExercise
                        )
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.bottom, 12)
    }
}

// MARK: - Session View
struct SessionView: View {
    let session: PlanSession

    @Binding var expandedSessions: Set<UUID>
    @Binding var selectedExercise: PlanExercise?
    @Binding var showingExerciseDetail: Bool
    @Binding var showLibraryExercise: Bool
    @Binding var matchingLibraryExercise: (Exercise, ExerciseCategory)?

    private let id = UUID()

    var body: some View {
        VStack(alignment: .leading) {
            Button {
                withAnimation(.spring()) {
                    if expandedSessions.contains(id) {
                        expandedSessions.remove(id)
                    } else {
                        expandedSessions.insert(id)
                    }
                }
            } label: {
                HStack {
                    sessionHeader
                    Spacer()
                    Image(systemName:
                            expandedSessions.contains(id)
                            ? "chevron.up"
                            : "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.05), radius: 3)
            }

            if expandedSessions.contains(id) {
                VStack(alignment: .leading, spacing: 16) {
                    if !session.warmUp.isEmpty {
                        SessionSectionView(
                            title: "Warm‑up",
                            items: session.warmUp,
                            iconName: "flame",
                            iconColor: .orange
                        )
                    }
                    mainWorkoutSection
                    if !session.coolDown.isEmpty {
                        SessionSectionView(
                            title: "Cool‑down",
                            items: session.coolDown,
                            iconName: "wind",
                            iconColor: .blue
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var sessionHeader: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.gray.opacity(0.4))   // neutral dot (no completion state here)
                .frame(width: 8, height: 8)

            if let colon = session.sessionTitle.firstIndex(of: ":") {
                let day = String(session.sessionTitle[..<colon])
                let focus = session.sessionTitle[session.sessionTitle.index(after: colon)...]
                    .trimmingCharacters(in: .whitespaces)

                Text(day)
                    .font(.headline)
                    .foregroundColor(.tealBlue)

                Text("· \(focus)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                // Fallback if there's no "Day: Focus" format
                Text(session.sessionTitle)
                    .font(.headline)
                    .foregroundColor(.tealBlue)
            }
        }
    }

    @ViewBuilder
    private var mainWorkoutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Main Workout")
                .font(.headline)
                .foregroundColor(.deepPurple)

            if session.mainWorkout.count > 1 {
                ForEach(session.mainWorkout) { ex in
                    ExerciseView(
                        exercise: ex,
                        originalName: ex.title,
                        selectedExercise: $selectedExercise,
                        showingExerciseDetail: $showingExerciseDetail,
                        showLibraryExercise: $showLibraryExercise,
                        matchingLibraryExercise: $matchingLibraryExercise
                    )
                }
            } else if let only = session.mainWorkout.first {
                let parts = splitTitle(only.title)
                ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                    ExerciseView(
                        exercise: PlanExercise(
                            type: inferType(from: part),
                            title: part,
                            description: only.description
                        ),
                        originalName: only.title,
                        selectedExercise: $selectedExercise,
                        showingExerciseDetail: $showingExerciseDetail,
                        showLibraryExercise: $showLibraryExercise,
                        matchingLibraryExercise: $matchingLibraryExercise
                    )
                }
            }
        }
    }

    private func splitTitle(_ t: String) -> [String] {
        let plus = t.split(separator: "+").map(String.init)
        guard plus.count > 1 else {
            let amp = t.split(separator: "&").map(String.init)
            return amp.count > 1 ? amp : [t]
        }
        return plus
    }

    private func inferType(from title: String) -> String {
        let l = title.lowercased()
        if l.contains("finger") { return "fingerboard" }
        if l.contains("boulder") { return "bouldering" }
        if l.contains("core")    { return "core" }
        if l.contains("strength") { return "strength" }
        if l.contains("power")   { return "power" }
        if l.contains("endurance") { return "endurance" }
        if l.contains("technique") { return "technique" }
        if l.contains("mobility")  { return "mobility" }
        return "climbing"
    }
}

// MARK: - Session Section View
struct SessionSectionView: View {
    let title: String
    let items: [String]
    let iconName: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.deepPurple)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top) {
                        Image(systemName: iconName)
                            .foregroundColor(iconColor)
                            .frame(width: 20)
                        Text(item)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

// MARK: - Exercise View
struct ExerciseView: View {
    let exercise: PlanExercise
    let originalName: String

    @Binding var selectedExercise: PlanExercise?
    @Binding var showingExerciseDetail: Bool
    @Binding var showLibraryExercise: Bool
    @Binding var matchingLibraryExercise: (Exercise, ExerciseCategory)?

    var body: some View {
        Button(action: didTap) {
            HStack(spacing: 12) {
                Image(systemName: exercise.iconName)
                    .foregroundColor(exercise.iconColor)
                    .frame(width: 24, height: 24)
                Text(exercise.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "info.circle")
                    .foregroundColor(.tealBlue)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func didTap() {
        let exact = PlanExercise(
            type: exercise.type,
            title: exercise.title,
            description: exercise.description
        )
        if let m = ExerciseLibraryManager
            .shared.findMatchingLibraryExercise(for: exact) {
            matchingLibraryExercise = m
            showLibraryExercise = true
            return
        }
        if exercise.title != originalName {
            let orig = PlanExercise(
                type: exercise.type,
                title: originalName,
                description: exercise.description
            )
            if let m = ExerciseLibraryManager
                .shared.findMatchingLibraryExercise(for: orig) {
                matchingLibraryExercise = m
                showLibraryExercise = true
                return
            }
        }
        selectedExercise = exercise
        showingExerciseDetail = true
    }
}

// MARK: - Plan Exercise Detail View
struct PlanExerciseDetailView: View {
    let exercise: PlanExercise
    let routeName: String

    @Environment(\.dismiss) private var dismiss
    @State private var matchingLibraryExercise: (Exercise, ExerciseCategory)?
    @State private var showExerciseLibrary = false

    var body: some View {
        VStack(spacing: 0) {
            DetailHeaderView {
                dismiss()
            }
            ScrollView {
                VStack(spacing: 20) {
                    Text("\(routeName) Training Plan")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 10)

                    exerciseCard

                    if matchingLibraryExercise != nil {
                        libraryButton
                    }
                }
            }
            .onAppear(perform: findMatch)
            .sheet(isPresented: $showExerciseLibrary) {
                if let (ex, cat) = matchingLibraryExercise {
                    NavigationView {
                        ExerciseDetailView(exercise: ex)
                            .navigationBarTitle(cat.name, displayMode: .inline)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var exerciseCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: exercise.iconName)
                    .font(.system(size: 30))
                    .foregroundColor(exercise.iconColor)
                    .frame(width: 60, height: 60)
                    .background(Color(.systemGray6))
                    .cornerRadius(30)
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.title)
                        .font(.title2)
                        .bold()
                    Text(exercise.type.capitalized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                    .foregroundColor(.tealBlue)
                Text(exercise.description)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var libraryButton: some View {
        Button(action: showLibrary) {
            HStack {
                Text("View in Exercise Library")
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
            }
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.ascendGreen, .tealBlue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }

    private func findMatch() {
        matchingLibraryExercise =
            ExerciseLibraryManager
                .shared
                .findMatchingLibraryExercise(for: exercise)
    }

    private func showLibrary() {
        showExerciseLibrary = true
        dismiss()
    }
}

// MARK: - Expanded Plan Detail View
struct ExpandedPlanDetailView: View {
    let plan: PlanModel
    let routeName: String
    let grade: String
    let planId: String

    @State private var selectedWeek = 1
    @State private var showSessionDetail = false
    @State private var selectedTracking: SessionTracking?
    @ObservedObject private var trackingManager = SessionTrackingManager.shared

    // total weeks in the plan
    private var totalWeeks: Int {
        (plan.weeks
            .compactMap { $0.title.extractWeekRange()?.upperBound }
            .max() ?? 0) - 1
    }

    // sessions for the currently‑selected week
    private var weekSessions: [SessionTracking] {
        trackingManager.getSessionsForWeek(planId: planId, weekNumber: selectedWeek)
    }

    // overall completion stats
    private var progressStats: (completed: Int, total: Int, percentage: Double) {
        trackingManager.getCompletionStats(planId: planId)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                progressCard
                weekPicker
                sessionRows
            }
            .padding(.bottom, 20)
        }
        .navigationBarHidden(true)
        .onAppear {
            trackingManager.initializeTrackingForPlan(planId: planId, plan: plan)
        }
        .onDisappear {
            // flush out any session changes before we leave this screen
            SessionTrackingManager.shared.saveAllData()
        }
        .sheet(isPresented: $showSessionDetail, onDismiss: {
            SessionTrackingManager.shared.saveAllData()
        }) {
            if let t = selectedTracking,
               let ps = findPlanSession(for: t) {
                SessionDetailView(
                    plan: plan,
                    planSession: ps,
                    sessionTracking: t
                )
            }
        }
    }

    // ─── HEADER ─────────────────────────────────────────
    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(routeName) Training Plan")
                .font(.title).bold().foregroundColor(.deepPurple)
            Text("Grade: \(grade)")
                .font(.headline).foregroundColor(.tealBlue)
            Text("\(totalWeeks) Weeks Total")
                .font(.subheadline).foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    // ─── PROGRESS CARD ──────────────────────────────────
    private var progressCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Overall Progress")
                    .font(.headline).foregroundColor(.deepPurple)
                Spacer()
                Text("\(progressStats.completed)/\(progressStats.total) Sessions Completed")
                    .font(.subheadline).foregroundColor(.gray)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 10)
                        .cornerRadius(5)
                    Rectangle()
                        .fill(Color.ascendGreen)
                        .frame(
                            width: geo.size.width * CGFloat(progressStats.percentage),
                            height: 10
                        )
                        .cornerRadius(5)
                }
            }
            .frame(height: 10)

            Text("\(Int(progressStats.percentage * 100))% Complete")
                .font(.caption).foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }

    // ─── WEEK PICKER ────────────────────────────────────
    private var weekPicker: some View {
        VStack(spacing: 10) {
            Text("Select Week")
                .font(.headline).foregroundColor(.deepPurple)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(1...totalWeeks, id: \.self) { w in
                        Button {
                            selectedWeek = w
                        } label: {
                            Text("Week \(w)")
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    selectedWeek == w
                                        ? Color.ascendGreen
                                        : Color.gray.opacity(0.2)
                                )
                                .foregroundColor(
                                    selectedWeek == w ? .white : .primary
                                )
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.bottom, 5)
            }
        }
        .padding(.horizontal)
    }

    // ─── SESSION ROWS ──────────────────────────────────
    private var sessionRows: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Week \(selectedWeek) Sessions")
                .font(.headline).foregroundColor(.deepPurple)

            if weekSessions.isEmpty {
                Text("No sessions scheduled for this week")
                    .foregroundColor(.gray)
                    .padding(.vertical)
            } else {
                ForEach(weekSessions.sorted(by: { dayIndex($0.dayOfWeek) < dayIndex($1.dayOfWeek) })) { st in
                    SessionRowView(session: st) {
                        selectedTracking = st
                        showSessionDetail = true
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // ─── DAY INDEX FOR SORTING ─────────────────────────
    private func dayIndex(_ day: String) -> Int {
        ["Monday":1,"Tuesday":2,"Wednesday":3,
         "Thursday":4,"Friday":5,"Saturday":6,"Sunday":7][day] ?? 0
    }

    // ─── LOOKUP FOR PLANSESSION ────────────────────────
    private func findPlanSession(for track: SessionTracking) -> PlanSession? {
        plan.weeks
            .flatMap { $0.sessions }
            .first {
                $0.sessionTitle.starts(
                    with: "\(track.dayOfWeek): \(track.focusName)"
                )
            }
    }
}



// MARK: - Session Row View
struct SessionRowView: View {
    let session: SessionTracking
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.dayOfWeek)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.deepPurple)
                }
                .frame(width: 80, alignment: .leading)

                VStack(alignment: .leading, spacing: 3) {
                    Text(session.focusName)
                        .font(.callout)
                    if session.isCompleted {
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else if !session.notes.isEmpty {
                        Text("Has notes")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle()
                        .stroke(session.isCompleted ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if session.isCompleted {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .bold))
                    }
                }
                .animation(.easeInOut, value: session.isCompleted)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Card View
struct PlanCardView<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3)
                .bold()
                .foregroundColor(.tealBlue)
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}
