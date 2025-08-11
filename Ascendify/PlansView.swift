//
//  PlansView.swift
//  Ascendify
//
//  Created by Ellis Barker on 08/02/2025.
//

import SwiftUI
import UIKit

struct PlansView: View {
    @ObservedObject var plansManager = GeneratedPlansManager.shared
    @State private var showGenerateSheet = false
    @State private var selectedPlan: PlanWrapper? = nil
    @State private var showPlanDetail = false
    @State private var planIndicesToDelete: IndexSet? = nil
    @State private var showPlanDeleteAlert = false
    
    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                HeaderView()
                
                if plansManager.isLoading {
                    ProgressView("Loading plans...")
                        .padding()
                } else if let error = plansManager.error {
                    VStack {
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .padding()
                        
                        Button("Retry") {
                            Task {
                                await plansManager.refreshPlans()
                            }
                        }
                        .padding()
                    }
                } else if plansManager.plans.isEmpty {
                    emptyStateView
                } else {
                    plansList
                }
                
                generateButton
            }
            .navigationBarHidden(true)
            
            // Plan detail overlay
            if showPlanDetail, let plan = selectedPlan {
                // Dim background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(
                        .asymmetric(
                            insertion: .opacity.animation(.easeIn(duration: 0.30)),
                            removal:  .opacity.animation(.easeOut(duration: 0.20))
                        )
                    )
                
                // Panel with asymmetric timing
                PlanDetailViewWrapper(planWrapper: plan, isPresented: $showPlanDetail)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).animation(.easeInOut(duration: 0.35)),
                            removal:  .move(edge: .trailing).animation(.easeInOut(duration: 0.25))
                        )
                    )
            }
            
        }
        .animation(.easeInOut, value: showPlanDetail)
        .sheet(isPresented: $showGenerateSheet) {
            GeneratePlanView()
        }
        .alert("Delete Training Plan?", isPresented: $showPlanDeleteAlert) {
            Button("Delete", role: .destructive) {
                // Haptic feedback
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()

                guard let indexSet = planIndicesToDelete else { return }

                // Capture IDs so we can close the overlay if its plan was deleted
                let idsToDelete: [UUID] = indexSet.compactMap { idx in
                    plansManager.plans.indices.contains(idx) ? plansManager.plans[idx].id : nil
                }

                Task {
                    // Delete in reverse order to avoid reindexing issues
                    for index in indexSet.sorted(by: >) {
                        await plansManager.deletePlanEverywhere(at: index)
                    }

                    // Close the detail overlay if its plan was deleted
                    if let selected = selectedPlan, idsToDelete.contains(selected.id) {
                        await MainActor.run {
                            withAnimation(.easeInOut) {
                                showPlanDetail = false
                                selectedPlan = nil
                            }
                        }
                    }

                    // Reset stored indices
                    await MainActor.run {
                        planIndicesToDelete = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                planIndicesToDelete = nil
            }
        } message: {
            Text("This will permanently remove the training plan. Are you sure?")
        }
        .refreshable {
            await plansManager.refreshPlans()
        }
        .onAppear {
            plansManager.checkForPlans()
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(alignment: .center, spacing: 20) {
            Spacer()
            
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
                .padding(.bottom, 10)
            
            Text("No Training Plans Yet")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Generate a personalised training plan for your climbing projects")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding(.top)
    }
    
    // MARK: - Plans List
    private var plansList: some View {
        List {
            ForEach(plansManager.plans) { planWrapper in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.35)) {
                        selectedPlan = planWrapper
                        showPlanDetail = true
                    }
                } label: {
                    PlanRowView(planWrapper: planWrapper)
                }
                .buttonStyle(PlainButtonStyle())
                .listRowInsets(EdgeInsets())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
            }
            .onDelete { indexSet in
                planIndicesToDelete = indexSet
                showPlanDeleteAlert = true
            }
        }
        .listStyle(PlainListStyle())
        .disabled(showPlanDetail)
    }
    
    // MARK: - Generate Button
    private var generateButton: some View {
        Button {
            showGenerateSheet = true
        } label: {
            Text("Generate New Plan")
                .foregroundColor(.offWhite)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.ascendGreen)
                .cornerRadius(8)
                .padding()
        }
    }
}
    
// MARK: - Plan Row View
struct PlanRowView: View {
    let planWrapper: PlanWrapper
    
    private var weekCount: Int {
        // Extract total weeks from phase titles (e.g., "Week 1-4" = 4 weeks)
        let maxWeek = planWrapper.plan.weeks.compactMap { week -> Int? in
            let pattern = "Week(?:s)? (\\d+)-(\\d+)"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(in: week.title, options: [], range: NSRange(week.title.startIndex..<week.title.endIndex, in: week.title)),
                  let endRange = Range(match.range(at: 2), in: week.title) else {
                return nil
            }
            return Int(week.title[endRange])
        }.max() ?? planWrapper.plan.weeks.count
        
        return maxWeek
    }
    
    private var sessionCount: Int {
        planWrapper.plan.weeks.reduce(0) { total, week in
            // Calculate sessions per phase and multiply by weeks in that phase
            let weeksInPhase = week.title.extractWeekRange()?.count ?? 1
            return total + (week.sessions.count * weeksInPhase)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header row with title and chevron
            HStack {
                Text("\(planWrapper.routeName) Training Plan")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            
            // Grade info
            HStack {
                Text("Grade: \(planWrapper.grade)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            
            // Plan details row with icons
            HStack(spacing: 16) {
                // Weeks indicator
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.tealBlue)
                    Text("\(weekCount) weeks")
                        .font(.caption)
                        .foregroundColor(.tealBlue)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.tealBlue.opacity(0.1))
                )
                
                // Sessions indicator
                HStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                        .font(.caption)
                        .foregroundColor(.ascendGreen)
                    Text("\(sessionCount) sessions")
                        .font(.caption)
                        .foregroundColor(.ascendGreen)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.ascendGreen.opacity(0.1))
                )
                
                // Plan type indicator
                HStack(spacing: 4) {
                    Image(systemName: "doc.text.fill")
                        .font(.caption)
                        .foregroundColor(.deepPurple)
                    Text("Training Plan")
                        .font(.caption)
                        .foregroundColor(.deepPurple)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.deepPurple.opacity(0.1))
                )
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Plan Detail Wrapper
struct PlanDetailViewWrapper: View {
    let planWrapper: PlanWrapper
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                DetailHeaderView {
                    isPresented = false
                }
                
                PlanDetailView(
                    plan: planWrapper.plan,
                    routeName: planWrapper.routeName,
                    grade: planWrapper.grade
                )
            }
        }
        .transition(.move(edge: .trailing))
    }
}
