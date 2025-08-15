//
//  APIEnvelope.swift
//  Ascendify
//
//  Created by Ellis Barker on 23/07/2025.
//

import Foundation

/// A generic container that matches the standard response shape returned by
/// the FastAPI backend. It wraps the actual data plus optional fields.
struct APIEnvelope<T: Decodable>: Decodable {
    /// The wrapped payload.
    let data: T

    /// Optional human‑readable message.
    let message: String?

    /// Optional success flag.
    let success: Bool?
}
