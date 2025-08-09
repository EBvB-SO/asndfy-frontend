//
//  APIHelpers.swift
//  Ascendify
//
//  Created by Ellis Barker on 12/06/2025.
//

import Foundation

extension URLRequest {
    mutating func addAuthHeader() {
        if let token = UserViewModel.shared.accessToken {
            let authValue = "Bearer \(token)"
            self.setValue(authValue, forHTTPHeaderField: "Authorization")
            print("✅ Added auth header: \(authValue)")
        } else {
            print("❌ No access token available")
        }
    }
}

// MARK: - Add this new extension for consistent authenticated requests
extension URLSession {
    /// Performs an authenticated data task with automatic token refresh on 401
    func authenticatedDataTask(
        with request: URLRequest,
        retryOnFailure: Bool = true,
        completion: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        
        return self.dataTask(with: request) { data, response, error in
            // Check for 401 and retry if needed
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 401,
               retryOnFailure {
                
                UserViewModel.shared.refreshTokenIfNeeded { success in
                    guard success else {
                        // Couldn't refresh - return original 401 response
                        completion(data, response, error)
                        return
                    }
                    
                    // Retry with refreshed token
                    var retryRequest = request
                    retryRequest.addAuthHeader() // Re-add the auth header with new token
                    
                    self.authenticatedDataTask(
                        with: retryRequest,
                        retryOnFailure: false, // Don't retry again
                        completion: completion
                    ).resume()
                }
            } else {
                // Not a 401 or already retried
                completion(data, response, error)
            }
        }
    }
    
    /// Async version with automatic token refresh
    func authenticatedData(for request: URLRequest) async throws -> (Data, URLResponse) {
        // First attempt
        let (data, response) = try await self.data(for: request)
        
        // Check for 401
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 401 {
            
            // Try to refresh token
            let refreshed = await withCheckedContinuation { continuation in
                UserViewModel.shared.refreshTokenIfNeeded { success in
                    continuation.resume(returning: success)
                }
            }
            
            guard refreshed else {
                // Couldn't refresh - force sign out and throw
                await MainActor.run {
                    UserViewModel.shared.signOut()
                }
                throw URLError(.userAuthenticationRequired)
            }
            
            // Retry with new token
            var retryRequest = request
            retryRequest.addAuthHeader()
            return try await self.data(for: retryRequest)
        }
        
        return (data, response)
    }
}
