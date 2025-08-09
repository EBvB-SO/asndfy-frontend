//
//  BadgeComponents.swift
//  Ascendify
//
//  Created by Ellis Barker on 15/03/2025.
//

import SwiftUI
import Foundation

// MARK: – BadgeView (unchanged)

struct BadgeView: View {
    let badge: BadgeData
    @State private var showingDetail = false

    var body: some View {
        VStack(spacing: 4) {
            badgeIcon
            badgeLabel
        }
        .frame(width: 70)             // fixed width so all badges align
        .onTapGesture { showingDetail = true }
        .sheet(isPresented: $showingDetail) {
            BadgeDetailView(badge: badge)
        }
    }

    private var badgeIcon: some View {
        ZStack {
            Circle()
                .fill(badge.isEarned ? Color.ascendGreen : Color.gray.opacity(0.25))
                .frame(width: 50, height: 50)
                .shadow(
                    color: badge.isEarned ? Color.ascendGreen.opacity(0.45) : .clear,
                    radius: 3,
                    x: 0,
                    y: 1
                )

            Image(systemName: badge.iconName)
                .font(.system(size: 28))
                .foregroundColor(badge.isEarned ? .white : Color.gray.opacity(0.6))
        }
    }

    private var badgeLabel: some View {
        Text(badge.name)
            .font(.caption2)
            .fontWeight(badge.isEarned ? .semibold : .regular)
            .foregroundColor(badge.isEarned ? .primary : .gray)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .frame(height: 30)
    }
}

/// Collapsible dropdown section that starts collapsed and expands to show badges
struct BadgesSection: View {
    let category: BadgeCategory
    let badges: [BadgeData]
    @State private var isExpanded: Bool = false

    private var categoryBadges: [BadgeData] {
        badges.filter { $0.category == category }
    }

    private var earnedCount: Int {
        categoryBadges.filter { $0.isEarned }.count
    }

    private var totalCount: Int {
        categoryBadges.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: category name + progress bar + dropdown arrow
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(alignment: .center) {
                    Text(category.rawValue)
                        .font(.headline)
                        .foregroundColor(.tealBlue)

                    Spacer()

                    Text("\(earnedCount)/\(totalCount)")
                        .font(.caption)
                        .foregroundColor(.gray)

                    ProgressView(value: Float(earnedCount), total: Float(totalCount))
                        .progressViewStyle(LinearProgressViewStyle(tint: .ascendGreen))
                        .frame(width: 70, height: 6)
                        .padding(.leading, 6)
                    
                    // Dropdown arrow
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.tealBlue)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                        .padding(.leading, 8)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
                .contentShape(Rectangle()) // Makes entire header tappable
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable content
            if isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(categoryBadges) { badge in
                            BadgeView(badge: badge)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

// MARK: – Previews

struct BadgeComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            BadgeView(badge: BadgeData(
                name: "Overhang Climber",
                description: "Completed an overhanging route",
                iconName: "arrow.up.right",
                isEarned: true,
                category: .styles,
                achievementDate: Date()
            ))

            Divider()

            BadgesSection(
                category: .styles,
                badges: [
                    BadgeData(
                        name: "Slab Climber",
                        description: "Completed a slab route",
                        iconName: "mountain.2",
                        isEarned: true,
                        category: .styles
                    ),
                    BadgeData(
                        name: "Crimpy Master",
                        description: "Completed a route with crimpy holds",
                        iconName: "hand.point.up.fill",
                        isEarned: false,
                        category: .styles
                    )
                ]
            )

            Divider()

            BadgesSection(
                category: .plans,
                badges: [
                    BadgeData(
                        name: "First Plan",
                        description: "Purchased your first plan",
                        iconName: "doc.text.fill",
                        isEarned: false,
                        category: .plans
                    )
                ]
            )
        }
        .padding()
    }
}
