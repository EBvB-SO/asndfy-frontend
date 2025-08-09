//
//  PlanModel.swift
//  Ascendify
//
//  Created by Ellis Barker on 08/02/2025.
//

import Foundation

/// A model matching the server's training plan response format
struct ServerPlanModel: Codable {
    let id: String
    let user_id: Int
    let route_name: String
    let grade: String
    let route_overview: String
    let training_overview: String
    let phases: [PlanWeek]
    let purchased_at: String
}

/// Matches the typical {"detail":"..."} error JSON that FastAPI sends
struct ServerError: Decodable {
    let detail: String
}

/// Plan Previewer Model
struct PlanPreviewData: Codable {
    let routeOverview: String
    let trainingApproach: String

    enum CodingKeys: String, CodingKey {
        case routeOverview = "route_overview"
        case trainingApproach = "training_approach"
    }
}

/// The main, fully decoded plan structure coming from the server.
struct PlanModel: Codable, Hashable {
    let routeOverview: String
    let trainingOverview: String
    let weeks: [PlanWeek]

    enum CodingKeys: String, CodingKey {
        case routeOverview = "route_overview"
        case trainingOverview = "training_overview"
        case weeks = "phases"
    }

    // Custom initializer for decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        routeOverview = try container.decodeIfPresent(String.self, forKey: .routeOverview) ?? ""
        trainingOverview = try container.decodeIfPresent(String.self, forKey: .trainingOverview) ?? ""
        weeks = try container.decode([PlanWeek].self, forKey: .weeks)
    }

    // Memberwise initializer
    init(routeOverview: String, trainingOverview: String, weeks: [PlanWeek]) {
        self.routeOverview = routeOverview
        self.trainingOverview = trainingOverview
        self.weeks = weeks
    }
}

struct PlanWeek: Codable, Hashable {
    let title: String
    let sessions: [PlanSession]
}

struct PlanSession: Codable, Hashable {
    let sessionTitle: String
    let warmUp: [String]
    let mainWorkout: [PlanExercise]
    let coolDown: [String]

    enum CodingKeys: String, CodingKey {
        case sessionTitle = "session_title"
        case warmUp = "warm_up"
        case mainWorkout = "main_workout"
        case coolDown = "cool_down"
    }
}

/// Make PlanExercise Identifiable so it works in SwiftUI ForEach
struct PlanExercise: Codable, Hashable, Identifiable {
    /// Unique ID for SwiftUI
    var id: UUID

    let type: String
    let title: String
    let description: String

    private enum CodingKeys: String, CodingKey {
        case type, title, description
    }

    // Generate a new UUID when decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        id = UUID()
    }

    /// Convenience initializer for manual instances
    init(
        id: UUID = UUID(),
        type: String,
        title: String,
        description: String
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
    }
}

/// A local wrapper if you want to store route info + PlanModel together
struct PlanWrapper: Identifiable, Hashable, Codable {
    let id: UUID
    let routeName: String
    let grade: String
    let plan: PlanModel

    init(routeName: String, grade: String, plan: PlanModel) {
        self.id = UUID()
        self.routeName = routeName
        self.grade = grade
        self.plan = plan
    }

    enum CodingKeys: String, CodingKey {
        case id, routeName, grade, plan
    }
}
