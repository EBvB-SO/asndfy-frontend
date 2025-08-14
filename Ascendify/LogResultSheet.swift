//
//  LogResultSheet.swift
//  Ascendify
//
//  Created by Ellis Barker on 14/08/2025.
//

import SwiftUI

struct LogResultSheet: View {
    let test: TestDefinition
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss
    var onSaved: (() -> Void)?
    @ObservedObject private var vm = TestsViewModel.shared
    
    @State private var value: Double = 0
    @State private var date: Date = Date()
    @State private var notes: String = ""
    @State private var errorBanner: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Result") {
                    HStack {
                        Text("Value")
                        Spacer()
                        TextField("0", value: $value, format: .number)
                            .keyboardType(.decimalPad)
                        Text(test.unit ?? "kg")
                            .foregroundColor(.secondary)
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                }
                
                if let err = errorBanner {
                    Text(err).foregroundColor(.red)
                }
            }
            .navigationTitle("Log Result")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .bold()
                }
            }
        }
    }
    
    private func save() {
        guard
            let email = userViewModel.userProfile?.email,
            let token = userViewModel.accessToken, !token.isEmpty
        else {
            errorBanner = "You're not signed in."
            return
        }
        
        errorBanner = nil
        
        Task {
            do {
                try await vm.submitResult(
                    for: test,
                    userEmail: email,
                    token: token,
                    value: value,
                    date: date,
                    notes: notes.isEmpty ? nil : notes
                )
                
                // Save succeeded — optionally refresh in the background
                try? await vm.loadResults(for: test, userEmail: email, token: token)
                
                dismiss()
                onSaved?()   // 👈 trigger refresh in TestDetailView
            } catch {
                errorBanner = "Failed to save: \(prettyNetworkError(error))"
            }
        }
    }
}
private func prettyNetworkError(_ error: Error) -> String {
    if let urlErr = error as? URLError {
        switch urlErr.code {
        case .notConnectedToInternet: return "No internet connection."
        case .timedOut: return "Request timed out."
        default: break
        }
    }
    return "Network error: \(error.localizedDescription)"
}
