//
//  TestModels.swift
//  Ascendify
//
//  Created by Ellis Barker on 13/08/2025.
//

import Foundation

// Shared enum used by both the detail and runner views
enum TestProtocolKind: Equatable, Codable {
    case twoArmMaxHang7s
    case oneArmMaxHang10s
    case sevenThreeRepeats   // 7:3
    case timeToFailure       // generic timer up
    case twoRepMaxPullup
}

struct TestDefinition: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String?
    let exercise_id: Int?
    let unit: String?
}

struct TestResult: Identifiable, Codable {
    let id: Int
    let testId: Int
    let date: Date
    let value: Double
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case testId = "test_id"
        case date
        case value
        case notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id     = (try? container.decode(Int.self, forKey: .id))    ?? -1
        testId = (try? container.decode(Int.self, forKey: .testId)) ?? -1
        date   = try container.decode(Date.self, forKey: .date)
        value  = try container.decode(Double.self, forKey: .value)
        notes  = try? container.decodeIfPresent(String.self, forKey: .notes)
    }
}

extension TestResult {
    var dateString: String {
        let f = DateFormatter()
        f.dateStyle = .short
        return f.string(from: date)
    }
}
