///
//  DetailHeaderView.swift
//  Ascendify
//
//  Created by Ellis Barker on 08/02/2025.
//

import SwiftUI

struct DetailHeaderView: View {
    /// Action to perform when back button is tapped
    let onBack: () -> Void

    var body: some View {
        ZStack {
            backgroundGradient
            content
        }
        .frame(height: 80)
    }

    // MARK: - Subviews

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [.ascendGreen, .vividPurple]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .ignoresSafeArea(edges: .top)
    }

    private var content: some View {
        HStack {
            backButton
            Spacer()
            logo
            Spacer()
            trailingSpacer
        }
    }

    private var backButton: some View {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding(.leading, 28)
    }

    private var logo: some View {
        Image("ascendify-logo")
            .resizable()
            .scaledToFit()
            .frame(height: 50)
            .padding()
    }

    private var trailingSpacer: some View {
        Spacer().frame(width: 44)
    }
}
