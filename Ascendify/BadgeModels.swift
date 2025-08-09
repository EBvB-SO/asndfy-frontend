//
//  BadgeModels.swift
//  Ascendify
//
//  Created by Ellis Barker on 15/03/2025.
//

import Foundation
import SwiftUI

// Badge data structure
struct BadgeData: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let iconName: String
    let isEarned: Bool
    let category: BadgeCategory
    let achievementDate: Date?
    let howToEarn: String
    
    init(
        name: String,
        description: String,
        iconName: String,
        isEarned: Bool,
        category: BadgeCategory,
        achievementDate: Date? = nil,
        howToEarn: String = "Complete the required actions to earn this badge."
    ) {
        self.name = name
        self.description = description
        self.iconName = iconName
        self.isEarned = isEarned
        self.category = category
        self.achievementDate = achievementDate
        self.howToEarn = howToEarn
    }
}

enum BadgeCategory: String, CaseIterable {
    case styles = "Climbing Styles"
    case plans = "Training Plans"
    case projects = "Projects"
    case logs = "Project Logs"
}

// Route Angle options
enum RouteAngle: String, CaseIterable, Codable {
    case slab = "slab"
    case vertical = "vertical"
    case overhang = "overhanging"
    case roof = "roof"
    
    var iconName: String {
        switch self {
        case .slab: return "mountain.2"
        case .vertical: return "arrow.up"
        case .overhang: return "arrow.up.right"
        case .roof: return "arrow.right"
        }
    }
}

// Route Length options
enum RouteLength: String, CaseIterable, Codable {
    case long = "long"
    case medium = "medium"
    case short = "short"
    case bouldery = "bouldery"
    
    var iconName: String {
        switch self {
        case .long: return "ruler.fill"
        case .medium: return "ruler"
        case .short: return "minus"
        case .bouldery: return "square.fill"
        }
    }
}

// Hold Type options
enum HoldType: String, CaseIterable, Codable {
    case crack = "crack"
    case crimpy = "crimpy"
    case slopers = "slopers"
    case jugs = "jugs"
    case pinches = "pinches"
    case pockets = "pockets"
    
    var iconName: String {
        switch self {
        case .crack: return "line.diagonal"
        case .crimpy: return "hand.point.up.fill"
        case .slopers: return "hand.wave.fill"
        case .jugs: return "circle.fill"
        case .pinches: return "hand.raised.fill"
        case .pockets: return "rectangle.compress.vertical" // Icon for pockets
        }
    }
}

// Route Style Options
enum RouteStyle: String, CaseIterable, Codable, Identifiable {
    case bouldery           = "Bouldery"
    case pumpy              = "Pumpy"
    case sustained          = "Sustained"
    case enduranceFocused   = "Endurance‑Focused"
    case powerEndurance     = "Power‑Endurance"
    case technical          = "Technical"
    case dynoDynamic        = "Dyno/Dynamic"
    case fingery            = "Fingery"
    
    var id: String { rawValue }
    
    /// Optional: a system icon to display alongside each style
    var iconName: String {
        switch self {
        case .bouldery:         return "mountain.2.fill"
        case .pumpy:            return "flame.fill"
        case .sustained:        return "infinity"
        case .enduranceFocused: return "tortoise.fill"
        case .powerEndurance:   return "bolt.heart.fill"
        case .technical:        return "hammer.fill"
        case .dynoDynamic:      return "figure.dynamic"
        case .fingery:          return "hand.raised.fill"
        }
    }
}
