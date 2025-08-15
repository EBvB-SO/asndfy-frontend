//
//  APIHelpers.swift
//  Ascendify
//
//  Created by Ellis Barker on 12/06/2025.
//

import Foundation

extension URLRequest {
    @MainActor
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

extension URLSession {
    /// Performs an authenticated request; automatically refreshes token on 401.
    func authenticatedData(for request: URLRequest) async throws -> (Data, URLResponse) {
        // First attempt
        let (data, response) = try await self.data(for: request)

        // If we get a 401, try to refresh the token once
        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            let refreshed = await UserViewModel.shared.refreshTokenIfNeeded()
            guard refreshed else {
                // Token refresh failed – sign out and throw
                await MainActor.run { UserViewModel.shared.signOut() }
                throw URLError(.userAuthenticationRequired)
            }

            // Build a new request with the refreshed token
            var newRequest = request
            await MainActor.run {
                newRequest.addAuthHeader()
            }
            return try await self.data(for: newRequest)
        }

        return (data, response)
    }
}
