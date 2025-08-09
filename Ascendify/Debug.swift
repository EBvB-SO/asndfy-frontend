//
//  Debug.swift
//  Ascendify
//
//  Created by Ellis Barker on 23/07/2025.
//

import Foundation

func debugPrintBody(_ data: Data) {
    if let s = String(data: data, encoding: .utf8) {
        print("🔴 Raw response body:\n\(s)")
    } else {
        print("🔴 Raw response body (non‑utf8, length \(data.count) bytes)")
    }
}
