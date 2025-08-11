//
//  SignUpView.swift
//  Ascendify
//
//  Created by Ellis Barker on 08/02/2025.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var agreedToLegal = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showLegalSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header view
            HeaderView()
            
            // Main content
            ScrollView {
                VStack(spacing: 25) {
                    Text("Sign Up")
                        .font(.title)
                        .bold()
                        .foregroundColor(.deepPurple)
                        .padding(.top, 20)
                    
                    // Form fields with consistent padding
                    VStack(spacing: 15) {
                        TextField("Full Name", text: $name)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        // Terms & Conditions toggle
                        HStack(alignment: .top) {
                            Toggle("", isOn: $agreedToLegal)
                                .labelsHidden()
                                .frame(width: 50)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("I agree to the Terms & Conditions, Privacy Policy and Health & Safety Waiver.")
                                    .font(.subheadline)
                                
                                Button("View Terms & Conditions") {
                                    showLegalSheet = true
                                }
                                .font(.footnote)
                                .foregroundColor(.tealBlue)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal)
                    
                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    // Sign Up button
                    Button(action: {
                        signUp()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(agreedToLegal ? Color.ascendGreen : Color.gray)
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .disabled(!agreedToLegal || isLoading)
                    
                    // Back to sign in button
                    Button("Already have an account? Sign In") {
                        dismiss()
                    }
                    .foregroundColor(.tealBlue)
                    .padding(.vertical)
                }
            }
        }
        .sheet(isPresented: $showLegalSheet) {
            LegalAndPrivacyView()
        }
        .navigationBarHidden(true)
    }
    
    func signUp() {
        // Clear any previous errors
        errorMessage = nil
        isLoading = true
        
        // Basic validation
        guard !name.isEmpty else {
            errorMessage = "Please enter your name"
            isLoading = false
            return
        }
        
        guard !email.isEmpty, email.contains("@") else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            return
        }
        
        // Call the view model to handle signup
        userViewModel.signUp(name: name, email: email, password: password) { success, error in
            isLoading = false
            
            if success {
                // ✅ Remove the manual isSignedIn assignment.
                // Instead, immediately sign in to obtain an access token.
                userViewModel.signIn(email: email, password: password) { signedIn, signInError in
                    if signedIn {
                        // Create local profile
                        var profile = UserProfile()
                        profile.name = name
                        profile.email = email
                        userViewModel.userProfile = profile
                        
                        // Mark that we still need to fill out the questionnaire
                        userViewModel.needsQuestionnaire = true
                        
                        // Optionally fetch any initial plans for the new user
                        GeneratedPlansManager.shared.clearPlans()
                        GeneratedPlansManager.shared.fetchPlansFromServer(email: email)
                        
                        print("✅ Sign‑up and auto sign‑in succeeded")
                    } else {
                        // If sign‑in fails, surface the error
                        errorMessage = signInError ?? "Failed to sign in after sign up"
                        print("❌ Auto sign‑in failed: \(errorMessage ?? "")")
                    }
                }
            } else {
                // Show the error
                errorMessage = error ?? "Failed to create account"
                print("Sign up failed: \(errorMessage ?? "Unknown error")")
            }
        }
    }
}
