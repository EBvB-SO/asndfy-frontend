//
//  UI+Components.swift
//  Ascendify
//
//  Created by Ellis Barker on 14/08/2025.
//

import SwiftUI

// MARK: - Brand helpers (shared)
struct BrandGradients {
    static let header = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.12, green: 0.75, blue: 0.72),   // teal-ish
            Color(red: 0.38, green: 0.26, blue: 0.91)    // purple-ish
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Reusable UI atoms (make them module-internal, not private)
struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.caption).fontWeight(.semibold)
            .foregroundColor(.secondary)
    }
}

struct Pill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption).bold()
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .foregroundStyle(.primary)
    }
}

struct BulletRow: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").bold()
            Text(text).fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

struct Card<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
