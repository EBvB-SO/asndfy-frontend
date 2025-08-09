//
//  ForgotPasswordView.swift
//  Ascendify
//
//  Created by You on 30/05/2025.
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var message: String? = nil
    @State private var isSuccess = false
    @State private var showResetView = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header
            DetailHeaderView(onBack: { dismiss() })

            // MARK: Form
            ScrollView {
                VStack(spacing: 20) {
                    Text("Reset Password")
                        .font(.title).bold()
                        .foregroundColor(.deepPurple)
                        .padding(.top, 30)

                    Text("Enter your email address and we'll send you a 6-digit code to reset your password.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal)

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal, 25)

                    statusMessage

                    resetButton

                    Spacer()
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showResetView) {
            ResetPasswordView(email: email)
              .environmentObject(userViewModel)
        }
    }

    // MARK: Status Message
    @ViewBuilder
    private var statusMessage: some View {
        if let text = message {
            Text(text)
                .foregroundColor(isSuccess ? .green : .red)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    // MARK: Reset Button
    private var resetButton: some View {
        Button(action: requestPasswordReset) {
            ZStack {
                Rectangle()
                    .fill(isLoading || !isValidEmail(email) ? Color.gray : Color.ascendGreen)
                    .cornerRadius(8)
                    .frame(height: 50)
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text("Send Reset Code")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
            }
        }
        .disabled(isLoading || !isValidEmail(email))
        .padding(.horizontal, 25)
        .padding(.top, 20)
    }

    // MARK: Action
    private func requestPasswordReset() {
        guard isValidEmail(email) else {
            message = "Please enter a valid email address"
            isSuccess = false
            return
        }

        isLoading = true
        message = nil

        ForgotPasswordService.requestCode(email: email) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let serverMessage):
                    message = serverMessage
                    isSuccess = true
                    // advance to the code entry screen after a brief pause
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showResetView = true
                    }
                case .failure(let error):
                    message = error.localizedDescription
                    isSuccess = false
                }
            }
        }
    }

    // MARK: Email Validation
    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }
}

// MARK: - Networking Service

struct ForgotPasswordService {
    /// Calls POST /forgot-password and returns the server’s "message" on success, with debug logs.
    static func requestCode(
        email: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let urlString = "\(UserViewModel.shared.baseURL)/auth/forgot-password"
        print("🔍 URL being called: \(urlString)")
        print("📧 Email being sent: \(email)")

        guard let url = URL(string: urlString) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ["email": email]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(.failure(URLError(.cannotParseResponse)))
            return
        }
        request.httpBody = body

        print("📤 Request headers: \(request.allHTTPHeaderFields ?? [:])")
        print("📤 Request body: \(String(data: body, encoding: .utf8) ?? "nil")")

        URLSession.shared.dataTask(with: request) { data, response, error in
            print("📥 Response received")

            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Status code: \(httpResponse.statusCode)")
                print("📥 Headers: \(httpResponse.allHeaderFields)")
            }

            if let data = data {
                let dataString = String(data: data, encoding: .utf8) ?? "Unable to decode"
                print("📥 Response body: \(dataString)")
            }

            // original handling
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let http = response as? HTTPURLResponse, let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            if http.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
                   let msg = json["message"] as? String {
                    completion(.success(msg))
                } else {
                    completion(.success("If an account with that email exists, you’ll receive a password reset email shortly."))
                }
            } else {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
                   let detail = json["detail"] as? String {
                    let err = NSError(domain: "ForgotPassword", code: http.statusCode,
                                      userInfo: [NSLocalizedDescriptionKey: detail])
                    completion(.failure(err))
                } else {
                    completion(.failure(URLError(.unknown)))
                }
            }
        }.resume()
    }

    /// POST /verify-reset-code
    static func verifyCodeAndReset(
        email: String,
        code: String,
        newPassword: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let url = URL(string: "\(UserViewModel.shared.baseURL)/auth/reset-password") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String:Any] = [
            "email": email,
            "code": code,
            "new_password": newPassword
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(.failure(URLError(.cannotParseResponse)))
            return
        }
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let http = response as? HTTPURLResponse, let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            if http.statusCode == 200 {
                completion(.success(()))
            } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
                    let detail = json["detail"] as? String {
                    let err = NSError(domain: "ResetPassword", code: http.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: detail])
                             completion(.failure(err))
            } else { completion(.failure(URLError(.unknown)))
                }
            }.resume()
    }
}

// Troubleshooter

struct EmailTroubleshootingView: View {
    let email: String
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Email Sent!")
                .font(.headline)
                .foregroundColor(.ascendGreen)
            
            Text("We sent a code to \(email)")
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Can't find the email?")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(alignment: .top) {
                    Text("1.")
                    Text("Check your spam/junk folder")
                }
                .font(.caption)
                
                HStack(alignment: .top) {
                    Text("2.")
                    Text("Add noreply@em7572.asndfy.com to your contacts")
                }
                .font(.caption)
                
                HStack(alignment: .top) {
                    Text("3.")
                    Text("Wait 2-5 minutes (some providers delay new senders)")
                }
                .font(.caption)
                
                if email.contains("hotmail") || email.contains("outlook") {
                    HStack(alignment: .top) {
                        Text("4.")
                        Text("Check 'Other' tab in Outlook")
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Button("Resend Code") {
                // Resend logic
            }
            .foregroundColor(.ascendGreen)
            .padding(.top)
        }
        .padding()
    }
}

// MARK: - Preview

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
          .environmentObject(UserViewModel.shared)
    }
}
