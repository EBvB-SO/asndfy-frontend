//
//  SettingsView.swift
//  Ascendify
//
//  Created by Ellis Barker on 08/02/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    
    @State private var showLegalPrivacy = false
    @State private var showDeleteConfirmation = false
    @State private var showDeleteSuccess = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    
    // ADDED: State for showing questionnaire
    @State private var showQuestionnaireSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom header instead of navigation title
            HeaderView()
            
            Form {
                // ADDED: New section for Profile & Data
                Section(header:
                    Text("PROFILE & DATA")
                        .font(.caption)
                        .textCase(.uppercase)
                        .foregroundColor(.deepPurple)
                ) {
                    Button {
                        showQuestionnaireSheet = true
                    } label: {
                        Label("Update Questionnaire", systemImage: "doc.text.fill")
                            .foregroundColor(.deepPurple)
                    }
                }
                
                Section(header:
                    Text("ACCOUNT")
                        .font(.caption)
                        .textCase(.uppercase)
                        .foregroundColor(.deepPurple)
                ) {
                    Text("Email: \(userViewModel.userProfile?.email ?? "")")
                    
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Delete Account", systemImage: "person.crop.circle.badge.xmark")
                                .foregroundColor(.red)
                            Text("Permanently remove your account and all data")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button {
                        userViewModel.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "arrow.right.square")
                            .foregroundColor(.red)
                    }
                    .alert(
                        Text("Confirm Account Deletion"),
                        isPresented: $showDeleteConfirmation,
                        actions: {
                            Button("Delete", role: .destructive) {
                                userViewModel.deleteAccount { success, error in
                                    if success {
                                        showDeleteSuccess = true
                                    } else {
                                        deleteErrorMessage = error ?? "Unknown error"
                                        showDeleteError = true
                                    }
                                }
                            }
                            Button("Cancel", role: .cancel) { }
                        },
                        message: {
                            Text("Are you sure you want to delete your account and all your data? This action cannot be undone.")
                        }
                    )
                    .alert(
                        Text("Account Deleted"),
                        isPresented: $showDeleteSuccess,
                        actions: {
                            Button("OK") { /* root view switches to SignInView */ }
                        },
                        message: {
                            Text("Your account and all data have been permanently deleted.")
                        }
                    )
                    .alert(
                        Text("Deletion Failed"),
                        isPresented: $showDeleteError,
                        actions: {
                            Button("OK", role: .cancel) { }
                        },
                        message: {
                            Text(deleteErrorMessage)
                        }
                    )
                }
                
                Section(header:
                    Text("LEGAL & PRIVACY")
                        .font(.caption)
                        .textCase(.uppercase)
                        .foregroundColor(.deepPurple)
                ) {
                    Button {
                        showLegalPrivacy = true
                    } label: {
                        Label("View Legal & Privacy", systemImage: "doc.text")
                            .foregroundColor(.deepPurple)
                    }
                    .sheet(isPresented: $showLegalPrivacy) {
                        NavigationView { LegalAndPrivacyView() }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        // ADDED: Sheet for questionnaire
        .sheet(isPresented: $showQuestionnaireSheet) {
            QuestionnaireView()
                .environmentObject(userViewModel)
        }
    }
}
