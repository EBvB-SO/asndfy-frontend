//
//  PlanDetailHeaderView.swift
//  Ascendify
//
//  Created by Ellis Barker on 02/08/2025.
//

import SwiftUI

struct PlanDetailHeaderView: View {
    let routeName: String
    let grade: String

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.ascendGreen, .vividPurple]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea(edges: .top)

            HStack {
                Spacer()

                VStack(spacing: 2) {
                    Text("\(routeName) Training Plan")
                        .foregroundColor(.white)
                        .font(.headline)
                        .fontWeight(.semibold)
                    if !grade.isEmpty {
                        Text("Grade: \(grade)")
                            .foregroundColor(.white.opacity(0.9))
                            .font(.subheadline)
                    }
                }

                Spacer()
            }
            .padding(.horizontal)
        }
        .frame(height: 80)
    }
}
