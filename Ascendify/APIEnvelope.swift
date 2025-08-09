//
//  APIEnvelope.swift
//  Ascendify
//
//  Created by Ellis Barker on 23/07/2025.
//

import Foundation

/// Matches responses shaped like:
/// {
///   "data": <T>,
///   "message": "...",
///   "success": true
/// }
struct APIEnvelope<T: Decodable>: Decodable {
    let data: T
    // You can add these if you need them later:
    // let message: String?
    // let success: Bool?
}
