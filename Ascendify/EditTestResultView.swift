//
//  EditTestResultView.swift
//  Ascendify
//
//  Created by Ellis Barker on 15/08/2025.
//

import SwiftUI

struct EditTestResultView: View {
    let test: TestDefinition
    let result: TestResult
    var onSaved: (() -> Void)? = nil

    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var vm = TestsViewModel.shared

    @State private var value: Double
    @State private var date: Date
    @State private var notes: String
    @State private var showDeleteAlert = false
    @State private var errorBanner: String?

    init(test: TestDefinition, result: TestResult, onSaved: (() -> Void)? = nil) {
        self.test = test
        self.result = result
        self.onSaved = onSaved
        _value = State(initialValue: result.value)
        _date = State(initialValue: result.date)
        _notes = State(initialValue: result.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Result") {
                    HStack {
                        Text("Value")
                        Spacer()
                        TextField("0", value: $value, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(minWidth: 72)
                        Text(test.unit ?? "")
                            .foregroundColor(.secondary)
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                }

                if let err = errorBanner {
                    Text(err).foregroundColor(.red)
                }
            }
            .navigationTitle("Edit Result")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .bold()
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .alert("Delete Result?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    delete()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func save() {
        guard let email = userViewModel.userProfile?.email,
              let token = userViewModel.accessToken, !token.isEmpty else {
            errorBanner = "You're not signed in."
            return
        }
        errorBanner = nil
        Task {
            do {
                try await vm.updateResult(
                    for: test,
                    userEmail: email,
                    token: token,
                    result: result,
                    newValue: value,
                    newDate: date,
                    newNotes: notes.isEmpty ? nil : notes
                )
                dismiss()
                onSaved?()
            } catch {
                errorBanner = "Failed to update: \(error.localizedDescription)"
            }
        }
    }

    private func delete() {
        guard let email = userViewModel.userProfile?.email,
              let token = userViewModel.accessToken, !token.isEmpty else {
            errorBanner = "You're not signed in."
            return
        }
        Task {
            do {
                try await vm.deleteResult(for: test, userEmail: email, token: token, resultId: result.id)
                dismiss()
                onSaved?()
            } catch {
                errorBanner = "Failed to delete: \(error.localizedDescription)"
            }
        }
    }
}
