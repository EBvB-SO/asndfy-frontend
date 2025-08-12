//
//  ProfileHeaderView.swift
//  Ascendify
//
//  Created by Ellis Barker on 12/08/2025.
//

import SwiftUI

struct ProfileHeaderView: View {
    var body: some View {
        ZStack {
            // Match the existing gradient from HeaderView
            LinearGradient(
                gradient: Gradient(colors: [.ascendGreen, .vividPurple]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea(edges: .top)

            // Centered Logo
            Image("ascendify-logo")
                .resizable()
                .scaledToFit()
                .frame(height: 50)

            // Right-side gear icon
            HStack {
                Spacer()
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        .foregroundColor(.white)
                        .padding(.trailing, 4)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .frame(height: 70)
        .fixedSize(horizontal: false, vertical: true)
    }
}
