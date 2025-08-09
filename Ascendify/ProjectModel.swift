//
//  ProjectModel.swift
//  Ascendify
//
//  Created by Ellis Barker on 15/03/2025.
//

import Foundation
import SwiftUI

// MARK: - MoodRating

enum MoodRating: String, Codable, CaseIterable {
    case sad = "sad"
    case neutral = "neutral"
    case happy = "happy"
    
    var iconName: String {
        switch self {
        case .sad: return "hand.thumbsdown.fill"
        case .neutral: return "minus.circle.fill"
        case .happy: return "hand.thumbsup.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .sad: return .red
        case .neutral: return .orange
        case .happy: return .green
        }
    }
}

// MARK: - LogEntry

struct LogEntry: Identifiable, Codable, Hashable {
    let id: String
    let date: String
    let content: String
    let mood: MoodRating?
    let created_at: String?
    let project_id: String?
    
    // For backward compatibility and creating new logs
    init(id: UUID = UUID(), date: Date = Date(), content: String, mood: MoodRating? = nil) {
        // Also store the log's ID as lowercase, if you want consistent matching
        self.id = id.uuidString.lowercased()
        self.date = ISO8601DateFormatter().string(from: date)
        self.content = content
        self.mood = mood
        self.created_at = nil
        self.project_id = nil
    }
    
    // Computed property for convenience
    var dateObject: Date {
        ISO8601DateFormatter().date(from: date) ?? Date()
    }
}

// MARK: - ProjectCreateRequest

struct ProjectCreateRequest: Codable {
    let route_name: String
    let grade: String
    let crag: String
    let description: String
    let route_angle: String
    let route_length: String
    let hold_type: String
}

// MARK: - ProjectModel

struct ProjectModel: Identifiable, Codable, Hashable {
    // Raw API fields
    var id: String
    let user_id: String?
    let route_name: String
    let grade: String
    let crag: String
    let description: String
    let route_angle: String
    let route_length: String
    let hold_type: String
    var is_completed: Bool
    var completion_date: String?
    let created_at: String
    var logs: [LogEntry]?
    
    // MARK: - Decoding from the server (forces `id` to lowercase)
    enum CodingKeys: String, CodingKey {
        case id, user_id, route_name, grade, crag, description
        case route_angle, route_length, hold_type
        case is_completed, completion_date, created_at, logs
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Force lowercase to ensure we match the DB exactly
        let rawId = try container.decode(String.self, forKey: .id)
        self.id = rawId.lowercased()
        
        self.user_id = try container.decodeIfPresent(String.self, forKey: .user_id)
        self.route_name = try container.decode(String.self, forKey: .route_name)
        self.grade = try container.decode(String.self, forKey: .grade)
        self.crag = try container.decode(String.self, forKey: .crag)
        self.description = try container.decode(String.self, forKey: .description)
        self.route_angle = try container.decode(String.self, forKey: .route_angle)
        self.route_length = try container.decode(String.self, forKey: .route_length)
        self.hold_type = try container.decode(String.self, forKey: .hold_type)
        self.is_completed = try container.decode(Bool.self, forKey: .is_completed)
        self.completion_date = try container.decodeIfPresent(String.self, forKey: .completion_date)
        self.created_at = try container.decode(String.self, forKey: .created_at)
        self.logs = try container.decodeIfPresent([LogEntry].self, forKey: .logs)
    }
    
    // MARK: - Creating projects locally (also forces lowercase ID)
    init(
        id: UUID = UUID(),
        routeName: String,
        grade: String,
        crag: String,
        description: String,
        routeAngle: RouteAngle = .vertical,
        routeLength: RouteLength = .medium,
        holdType: HoldType = .jugs,
        logEntries: [LogEntry] = [],
        isCompleted: Bool = false,
        completionDate: Date? = nil
    ) {
        // Force the new ID to lowercase
        self.id = id.uuidString.lowercased()
        self.user_id = nil
        self.route_name = routeName
        self.grade = grade
        self.crag = crag
        self.description = description
        self.route_angle = routeAngle.rawValue.lowercased()
        self.route_length = routeLength.rawValue.lowercased()
        self.hold_type = holdType.rawValue.lowercased()
        self.logs = logEntries
        self.is_completed = isCompleted
        self.completion_date = completionDate != nil
            ? ISO8601DateFormatter().string(from: completionDate!)
            : nil
        self.created_at = ISO8601DateFormatter().string(from: Date())
    }
    
    // MARK: - Computed properties for the rest of the app
    var routeName: String { route_name }
    var routeAngle: RouteAngle {
        let result = RouteAngle(rawValue: route_angle.lowercased()) ?? .vertical
        return result
    }
    
    var routeLength: RouteLength {
        let result = RouteLength(rawValue: route_length.lowercased()) ?? .medium
        return result
    }
    
    var holdType: HoldType {
        let result = HoldType(rawValue: hold_type.lowercased()) ?? .jugs
        return result
    }

    var isCompleted: Bool {
        is_completed
    }
    var completionDate: Date? {
        guard let dateStr = completion_date else { return nil }
        return ISO8601DateFormatter().date(from: dateStr)
    }
    var logEntries: [LogEntry] {
        logs ?? []
    }
}
