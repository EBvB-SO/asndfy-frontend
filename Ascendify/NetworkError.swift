//
//  NetworkError.swift
//  Ascendify
//
//  Created by Ellis Barker on 19/06/2025.
//

// NetworkError.swift
import Foundation

extension NetworkError {
    static func handleAuthenticationError() {
        // Centralized handling: sign out, show alert, etc.
        DispatchQueue.main.async {
            UserViewModel.shared.signOut()
            // Post notification for UI to show login screen
            NotificationCenter.default.post(
                name: .authenticationRequired,
                object: nil
            )
        }
    }
}

// Define the notification name
extension Notification.Name {
    static let authenticationRequired = Notification.Name("authenticationRequired")
}
