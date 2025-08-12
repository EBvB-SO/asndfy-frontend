//
//  DashboardView.swift
//  Ascendify
//
//  Created by Ellis Barker on 12/08/2025.
//

import SwiftUI

struct DashboardView: View {
    let userEmail: String
    let token: String
    
    @State private var dto: DashboardDTO?
    @State private var loading = true
    @State private var error: String?
    
    private let titleColor = Color(Brand.slate)
    
    // The exact 6-axis order from backend
    private let orderedAbilityLabels = [
        "Finger Strength",
        "Power",
        "Power Endurance",
        "Endurance",
        "Core Strength",
        "Flexibility"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if loading {
                ProgressView("Loading dashboard…")
            } else if let dto {
                
                // 1) Session Completion (Line)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Session Completion Trends")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(titleColor)
                    
                    LineChartViewSwiftUI(
                        config: .init(
                            completionRates: dto.sessionCompletion.map { $0.completionRate },
                            completedSessions: dto.sessionCompletion.map { Double($0.completedSessions) },
                            xLabels: dto.sessionCompletion.map { $0.weekLabel }
                        )
                    )
                    .frame(height: 240)
                }
                
                // 2) Abilities (Radar) — bigger + custom bottom legend
                VStack(alignment: .leading, spacing: 10) {
                    Text("Climbing Abilities Overview")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(titleColor)

                    RadarChartViewSwiftUI(config: radarConfig(from: dto))
                        .frame(maxWidth: .infinity)
                        .frame(height: 390)            // 380–400 works; pick what looks best
                        .padding(.vertical, -12)       // <-- crops DGCharts’ leftover top/bottom gaps

                    // Compact SwiftUI legend at the bottom (unchanged)
                    HStack(spacing: 16) {
                        LegendDot(color: .systemGray);  Text("Initial")
                            .font(.system(size: 13)).foregroundColor(.secondary)
                        LegendDot(color: .systemTeal);  Text("Current")
                            .font(.system(size: 13)).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 0)
                }
                
                // 3) Exercise Type Distribution (Pie)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Exercise Type Distribution")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(titleColor)
                    
                    PieChartViewSwiftUI(
                        config: .init(
                            slices: dto.exerciseDistribution.map { .init(label: $0.type, value: $0.percentage) }
                        )
                    )
                    .frame(height: 260)
                }
            } else {
                Text(error ?? "Failed to load dashboard").foregroundColor(.red)
            }
        }
        .padding()
        .task { await load() }
    }
    
    private func radarConfig(from dto: DashboardDTO) -> RadarChartConfig {
        // Keep axis order stable for labels around the web
        let axes = orderedAbilityLabels
        let maxScale: Double = 5.0
        
        let initial = axes.map { label in
            let v = dto.abilities.initial[label] ?? 0
            return min(1.0, max(0.0, v / maxScale))
        }
        let current = axes.map { label in
            let v = dto.abilities.current[label] ?? 0
            return min(1.0, max(0.0, v / maxScale))
        }
        
        // Debug to confirm non-zero values are sent to the chart:
        print("🟡 Radar initial (0..1):", initial)
        print("🟡 Radar current (0..1):", current)
        
        return .init(axes: axes, initial: initial, current: current)
    }
    
    private func load() async {
        do {
            loading = true
            dto = try await AnalyticsAPI.fetchDashboard(email: userEmail, token: token)
            if let dto {
                print("🔎 abilities.initial =", dto.abilities.initial)
                print("🔎 abilities.current =", dto.abilities.current)
            }
        } catch {
            self.error = error.localizedDescription
            self.dto = nil
        }
        loading = false
    }
}

// MARK: - Tiny legend dot used under the radar

private struct LegendDot: View {
    var color: UIColor
    var body: some View {
        Circle()
            .fill(Color(color))
            .frame(width: 12, height: 12)
    }
}
