//
//  ProfileView.swift
//  Ascendify
//
//  Created by Ellis Barker on 08/02/2025.
//  Updated by ChatGPT on 01/06/2025 (v3).
//

import SwiftUI
import Foundation

struct ProfileView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @ObservedObject var plansManager = GeneratedPlansManager.shared
    @ObservedObject var projectsManager = ProjectsManager.shared
    // REMOVED: @State private var showQuestionnaireSheet = false

    // Generate badges via helper
    private var badges: [BadgeData] {
        ProfileBadgeHelper.generateBadges(
            userProfile: userViewModel.userProfile,
            planCount: plansManager.plans.count,
            projectsManager: projectsManager
        )
    }

    var body: some View {
        ZStack {
            // Slight background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.deepPurple.opacity(0.08),
                    Color.ascendGreen.opacity(0.04)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HeaderView()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // MARK: – Greeting Card (with only "Hello, Name")
                        ProfileCard {
                            HStack(alignment: .center, spacing: 8) {
                                Text("Welcome back")
                                    .foregroundColor(.deepPurple)
                                    .font(.headline)

                                if let name = userViewModel.userProfile?.name, !name.isEmpty {
                                    Text(name)
                                        .font(.headline)
                                        .fontWeight(.medium)
                                } else {
                                    Text("Climber")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)

                        // MARK: – Climbing Stats as Two Rows of Three Cards
                        ProfileCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Climbing Stats")
                                    .font(.headline)
                                    .foregroundColor(.tealBlue)

                                // Two rows, three columns
                                StatsGridView(
                                    currentGrade: userViewModel.userProfile?.currentClimbingGrade ?? "--",
                                    maxBoulderGrade: userViewModel.userProfile?.maxBoulderGrade ?? "--",
                                    totalProjects: projectsManager.totalProjects,
                                    completedProjects: projectsManager.completedProjects,
                                    totalLogs: projectsManager.totalLogEntries,
                                    totalPlans: plansManager.plans.count
                                )
                                .padding(.top, 6)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                        .padding(.horizontal)

                        // MARK: – Badges / Achievements Section
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Your Achievements")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.deepPurple)
                                .padding(.horizontal)

                            ForEach(BadgeCategory.allCases, id: \.self) { category in
                                BadgesSection(category: category, badges: badges)
                            }
                        }

                        // REMOVED: "Edit Questionnaire" button section
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        // REMOVED: .sheet(isPresented: $showQuestionnaireSheet) { ... }
    }
    
    // MARK: - DEBUG FUNCTIONS (INSIDE THE STRUCT)
    private func testAuth() {
        guard let url = URL(string: "http://127.0.0.1:8001/projects/debug/auth-test") else {
            print("❌ Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.addAuthHeader()
        
        print("🔍 Testing auth with token: \(userViewModel.accessToken?.prefix(20) ?? "none")...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Auth test error: \(error)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response type")
                    return
                }
                
                print("📥 Auth test status: \(httpResponse.statusCode)")
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("✅ Auth test response: \(responseString)")
                } else {
                    print("❌ No response data")
                }
            }
        }.resume()
    }
    
    private func testProjectDetail() {
        // Test with a real project ID if you have one, or use a dummy one
        guard let firstProject = projectsManager.projects.first else {
            print("❌ No projects available to test")
            return
        }
        
        let projectId = firstProject.id.lowercased()
        guard let url = URL(string: "http://127.0.0.1:8001/projects/detail/\(projectId)") else {
            print("❌ Invalid project detail URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.addAuthHeader()
        
        print("🔍 Testing project detail for ID: \(projectId)")
        print("🔍 Using token: \(userViewModel.accessToken?.prefix(20) ?? "none")...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Project detail test error: \(error)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response type")
                    return
                }
                
                print("📥 Project detail status: \(httpResponse.statusCode)")
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("📥 Project detail response: \(responseString)")
                } else {
                    print("❌ No response data")
                }
            }
        }.resume()
    }
    
    private func testBackendConnection() {
        guard let url = URL(string: "http://127.0.0.1:8001/training_plans/test") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Test failed: \(error)")
            } else if let httpResponse = response as? HTTPURLResponse {
                print("✅ Test response: \(httpResponse.statusCode)")
                if let data = data, let body = String(data: data, encoding: .utf8) {
                    print("✅ Body: \(body)")
                }
            }
        }.resume()
    }
}

/// Lays out six stats in two rows of three columns each.
/// Each "card" is forced to the same size so none are larger than others.
struct StatsGridView: View {
    let currentGrade: String
    let maxBoulderGrade: String
    let totalProjects: Int
    let completedProjects: Int
    let totalLogs: Int
    let totalPlans: Int

    /// Each stat has an icon, label, and a string value
    private struct StatItem {
        let iconName: String
        let label: String
        let value: String
    }

    private var stats: [StatItem] {
        [
            StatItem(iconName: "figure.climbing", label: "Sport Grade", value: currentGrade),
            StatItem(iconName: "circle.square", label: "Boulder Grade", value: maxBoulderGrade),
            StatItem(iconName: "flag.fill", label: "Projects", value: "\(totalProjects)"),
            StatItem(iconName: "hand.thumbsup.fill", label: "Sends", value: "\(completedProjects)"),
            StatItem(iconName: "doc.text.fill", label: "Logs", value: "\(totalLogs)"),
            StatItem(iconName: "book.fill", label: "Plans", value: "\(totalPlans)")
        ]
    }

    /// Three flexible columns → two rows in a grid
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
            ForEach(stats, id: \.label) { stat in
                VStack(spacing: 6) {
                    // Force the circle to a fixed size (44×44) so every icon is identical
                    ZStack {
                        Circle()
                            .fill(Color.ascendGreen.opacity(0.1))
                            .frame(width: 44, height: 44)

                        Image(systemName: stat.iconName)
                            .font(.system(size: 20))
                            .foregroundColor(.ascendGreen)
                    }

                    Text(stat.label)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                    Text(stat.value)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, minHeight: 96) // same min‐height for each card
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
                )
            }
        }
    }
}
