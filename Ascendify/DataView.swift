//
//  DataView.swift
//  Ascendify
//
//  Created by Ellis Barker on 12/08/2025.
//

import SwiftUI

struct DataView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // reuse existing header for consistency
            HeaderView()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Training Analytics")
                        .font(.headline)
                        .foregroundColor(.tealBlue)
                        .padding(.horizontal)
                    
                    // Show dashboard or a placeholder if the user isn't signed in
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
