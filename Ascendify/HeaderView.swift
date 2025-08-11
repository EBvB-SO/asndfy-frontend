//
//  HeaderView.swift
//  Ascendify
//
//  Created by Ellis Barker on 08/02/2025.
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.ascendGreen, .vividPurple]),
                startPoint: .leading,
                endPoint: .trailing
                )
                .ignoresSafeArea(edges: .top)
            
            Image("ascendify-logo")
                .resizable()
                .scaledToFit()
                .frame(height: 50) // Reduced from 50 to 40 for consistency
                .padding(.vertical, 8) // Added vertical padding for consistent height
            }
            .frame(height: 70) // Reduced from 80 to 60 for consistency
            .fixedSize(horizontal: false, vertical: true)
        }
    }
