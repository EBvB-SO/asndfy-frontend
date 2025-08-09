//
//  PaymentManager.swift
//  Ascendify
//
//  Created by Ellis Barker on 08/02/2025.
//

import Foundation

class PaymentManager: ObservableObject {
    static let shared = PaymentManager()
    
    func purchasePlan(completion: @escaping (Bool) -> Void) {
        // Simulate a payment delay/processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // We’ll just say it succeeded
            completion(true)
        }
    }
}

