//
//  UserScopedStorage.swift
//  Ascendify
//
//  Created by Ellis Barker on 10/08/2025.
//

import Foundation

enum UserScopedStorage {
    static func key(_ base: String, email: String) -> String {
        "\(base)_\(email.lowercased())"
    }
}
