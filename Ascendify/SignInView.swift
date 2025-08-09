//
//  SignInView.swift
//  Ascendify
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMsg: String? = nil
    @State private var isLoading = false
    @State private var showSignUp = false
    @State private var showForgotPassword = false // New state for forgot password sheet
    
    var body: some View {
        VStack(spacing: 0) {
            // Top header
            HeaderView()
            
            // Main content
            VStack(spacing: 25) {
                Spacer()
                
                Text("Sign In")
                    .font(.title)
                    .bold()
                
                // Input fields
                VStack(spacing: 15) {
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
                    
                    // Add Forgot Password button
                    Button("Forgot Password?") {
                                            showForgotPassword = true
                                        }
                                        .foregroundColor(.tealBlue)
                                        .font(.footnote)
                                        .frame(maxWidth: .infinity) // This centers the button
                                        .padding(.top, 4)
                                    }
                                    .padding(.horizontal, 25)
                
                // Sign in button
                Button(action: signIn) {
                    ZStack {
                        Rectangle()
                            .fill(Color.ascendGreen)
                            .cornerRadius(8)
                            .frame(height: 50)
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign In")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .disabled(isLoading)
                .padding(.horizontal, 25)
                
                // Error message
                if let error = errorMsg {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                
                Spacer()
                
                // Sign up link
                Button("Don't have an account? Sign Up") {
                    showSignUp = true
                }
                .foregroundColor(.tealBlue)
                .padding(.bottom, 30)
            }
        }
        .fullScreenCover(isPresented: $showSignUp) {
            SignUpView()
                .environmentObject(userViewModel)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
              .environmentObject(userViewModel)
        }
    }
    
    func signIn() {
        // Input validation
        guard !email.isEmpty, email.contains("@") else {
            errorMsg = "Please enter a valid email"
            return
        }
        
        guard !password.isEmpty else {
            errorMsg = "Please enter your password"
            return
        }
        
        isLoading = true
        errorMsg = nil
        
        userViewModel.signIn(email: email, password: password) { success, error in
            isLoading = false
            
            if !success {
                errorMsg = error ?? "Invalid credentials."
                print("Sign in failed: \(errorMsg ?? "Unknown error")")
            } else {
                print("Sign in succeeded")
            }
        }
    }
}

// 3. Add this function to UserViewModel.swift
// to handle server-side part of password reset

// Add this method inside the UserViewModel class
func requestPasswordReset(email: String, completion: @escaping (Bool, String?) -> Void) {
    guard let url = URL(string: "\(UserViewModel.shared.baseURL)/auth/forgot-password") else {
        completion(false, "Invalid URL")
        return
    }
    
    // Create request body
    let body: [String: String] = [
        "email": email
    ]
    
    // Set up the request
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // Serialize the body to JSON
    guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
        completion(false, "Failed to create request")
        return
    }
    request.httpBody = jsonData
    
    // Send the request
    URLSession.shared.dataTask(with: request) { data, response, error in
        DispatchQueue.main.async {
            if let error = error {
                completion(false, "Network error: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false, "Invalid response from server")
                return
            }
            
            // Success case - password reset email should be sent
            if httpResponse.statusCode == 200 {
                completion(true, "Password reset instructions have been sent to your email.")
            } else {
                // Try to parse error from response
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let detail = json["detail"] as? String {
                    completion(false, detail)
                } else {
                    completion(false, "Failed to request password reset. Please try again later.")
                }
            }
        }
    }.resume()
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView().environmentObject(UserViewModel())
    }
}
