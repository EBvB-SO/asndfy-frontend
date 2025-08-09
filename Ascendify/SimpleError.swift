//
//  SimpleError.swift
//  Ascendify
//
//  Created by Ellis Barker on 13/04/2025.
//

import Foundation

/// A simplified error type for Ascendify that works with existing code
enum SimpleError: Error, Identifiable {
    case networkError(String)
    case authError(String)
    case dataError(String)
    case offlineError
    case genericError(String)
    
    var id: String {
        // Simple ID for Identifiable conformance
        switch self {
        case .networkError(let message): return "network-\(message.hashValue)"
        case .authError(let message): return "auth-\(message.hashValue)"
        case .dataError(let message): return "data-\(message.hashValue)"
        case .offlineError: return "offline"
        case .genericError(let message): return "generic-\(message.hashValue)"
        }
    }
    
    var message: String {
        switch self {
        case .networkError(let message): return "Network error: \(message)"
        case .authError(let message): return "Authentication error: \(message)"
        case .dataError(let message): return "Data error: \(message)"
        case .offlineError: return "You're currently offline"
        case .genericError(let message): return message
        }
    }
}
