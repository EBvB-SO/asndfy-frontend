//
//  BadgeDetailView.swift
//  Ascendify
//
//  Created by Ellis Barker on 15/03/2025.
//

import SwiftUI
import Foundation

struct BadgeDetailView: View {
    let badge: BadgeData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                content
            }
            .navigationBarTitle("Badge Details", displayMode: .inline)
        }
    }

    // MARK: - Content Sections

    private var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerSection
            descriptionSection
            howToEarnSection
            Spacer()
        }
        .padding()
    }

    private var headerSection: some View {
        HStack {
            badgeIcon
            badgeTitle
        }
        .padding(.bottom, 10)
    }

    private var badgeIcon: some View {
        ZStack {
            Circle()
                .fill(badge.isEarned ? Color.ascendGreen : Color.gray.opacity(0.3))
                .frame(width: 80, height: 80)

            Image(systemName: badge.iconName)
                .font(.system(size: 40))
                .foregroundColor(badge.isEarned ? .white : .gray)
        }
    }

    private var badgeTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(badge.name)
                .font(.title2)
                .bold()

            if badge.isEarned, let date = badge.achievementDate {
                Text("Earned on \(dateFormatter.string(from: date))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.leading, 10)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Description")
                .font(.headline)
            Text(badge.description)
        }
        .padding(.bottom, 10)
    }

    private var howToEarnSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("How to Earn")
                .font(.headline)
            Text(badge.howToEarn)
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}
