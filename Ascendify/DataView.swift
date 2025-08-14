//
//  DataView.swift
//  Ascendify
//
//  Created by Ellis Barker on 12/08/2025.
//

import SwiftUI

struct DataView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var showTests = false

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // ------------------------------------------------------------
                    // Assessments
                    // ------------------------------------------------------------
                    Text("Assessments")
                        .font(.headline)
                        .foregroundColor(.tealBlue)
                        .padding(.horizontal)

                    Button {
                        showTests = true
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemTeal).opacity(0.15))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "testtube.2")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(Color(.systemTeal))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Open Testing")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Color(Brand.slate))
                                Text("Run strength & capacity tests, then log results.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }

                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                        .padding(.horizontal, 16)   // side padding
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)         // keep card off screen edges
                    .sheet(isPresented: $showTests) {
                        TestsView()
                            .environmentObject(userViewModel)
                    }

                    // ------------------------------------------------------------
                    // Training Analytics
                    // ------------------------------------------------------------
                    Text("Training Analytics")
                        .font(.headline)
                        .foregroundColor(.tealBlue)
                        .padding(.horizontal)

                    if let email = userViewModel.userProfile?.email,
                       let token = userViewModel.accessToken, !token.isEmpty {
                        ProfileCard {
                            DashboardView(userEmail: email, token: token)
                                .padding()
                        }
                        .padding(.horizontal)
                    } else {
                        ProfileCard {
                            Text("Sign in to view analytics")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
    }
}
