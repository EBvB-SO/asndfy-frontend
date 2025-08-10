//
//  ResetPasswordView.swift
//  Ascendify
//
//  Created by Ellis Barker on 30/05/2025.
//

import SwiftUI

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userViewModel: UserViewModel
    
    let email: String
    @State private var code = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var message: String? = nil
    @State private var isSuccess = false
    @State private var showSignIn = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            ScrollView { formContent }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showSignIn) {
            SignInView()
                .environmentObject(userViewModel)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        DetailHeaderView(onBack: { dismiss() })
    }
    
    // MARK: - Form Content
    
    private var formContent: some View {
        VStack(spacing: 20) {
            titleSection
            codeInstructions
            codeInput
            passwordFields
            statusMessage
            resetButton
            Spacer()
        }
        .padding(.bottom, 20)
    }
    
    private var titleSection: some View {
        VStack(spacing: 10) {
            Text("Enter Reset Code")
                .font(.title)
                .bold()
                .foregroundColor(.deepPurple)
            
            Text(email)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.top, 30)
    }
    
    private var codeInstructions: some View {
        Text("Enter the 6-digit code we sent to your email")
            .multilineTextAlignment(.center)
            .foregroundColor(.gray)
            .padding(.horizontal)
    }
    
    private var codeInput: some View {
        VStack(spacing: 10) {
            TextField("6-digit code", text: $code)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title2)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(code.count == 6 ? Color.ascendGreen : Color.clear, lineWidth: 2)
                )
            
            Text("\(code.count)/6 digits")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 25)
    }
    
    private var passwordFields: some View {
        VStack(spacing: 15) {
            SecureField("New Password", text: $newPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            SecureField("Confirm Password", text: $confirmPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            // Password requirements
            VStack(alignment: .leading, spacing: 5) {
                Text("Password must:")
                    .font(.caption)
                    .fontWeight(.medium)
                HStack {
                    Image(systemName: passwordLengthValid ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(passwordLengthValid ? .green : .gray)
                        .font(.caption)
                    Text("Be at least 6 characters")
                        .font(.caption)
                }
                HStack {
                    Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(passwordsMatch ? .green : .gray)
                        .font(.caption)
                    Text("Match confirmation")
                        .font(.caption)
                }
            }
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 25)
    }
    
    @ViewBuilder
    private var statusMessage: some View {
        if let text = message {
            Text(text)
                .foregroundColor(isSuccess ? .green : .red)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var resetButton: some View {
        Button(action: resetPassword) {
            ZStack {
                Rectangle()
                    .fill(canResetPassword ? Color.ascendGreen : Color.gray)
                    .cornerRadius(8)
                    .frame(height: 50)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text("Reset Password")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
            }
        }
        .disabled(!canResetPassword || isLoading)
        .padding(.horizontal, 25)
        .padding(.top, 20)
    }
    
    // MARK: - Computed Properties
    
    private var passwordLengthValid: Bool {
        newPassword.count >= 6
    }
    
    private var passwordsMatch: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }
    
    private var canResetPassword: Bool {
        code.count == 6 && passwordLengthValid && passwordsMatch
    }
    
    // MARK: - Actions
    
    // ResetPasswordView.swift

    private func resetPassword() {
        isLoading = true
        message = nil

        ForgotPasswordService.verifyCodeAndReset(
          email: email,
          code: code,
          newPassword: newPassword
        ) { result in
          DispatchQueue.main.async {
            isLoading = false

              switch result {
              case .success:
                  // update Keychain via your VM
                  userViewModel.saveCredentials(email: email, password: newPassword)

                  message = "Password reset successfully!"
                  isSuccess = true
                  DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                      showSignIn = true
                  }

              case .failure(let error):
              message = error.localizedDescription
              isSuccess = false
            }
          }
        }
    }
}
