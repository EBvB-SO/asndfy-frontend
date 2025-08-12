//
//  DashboardModels.swift
//  Ascendify
//
//  Created by Ellis Barker on 12/08/2025.
//

import Foundation

struct DashboardDTO: Decodable {
    struct WeekData: Decodable {
        let weekLabel: String
        let completedSessions: Int
        let completionRate: Double
    }
    struct Abilities: Decodable {
        let initial: [String: Double]
        let current: [String: Double]
    }
    struct DistItem: Decodable {
        let type: String
        let count: Int
        let percentage: Double
    }

    let sessionCompletion: [WeekData]
    let abilities: Abilities
    let exerciseDistribution: [DistItem]
}
