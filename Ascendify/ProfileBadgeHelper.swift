//
//  ProfileBadgeHelper.swift
//  Ascendify
//
//  Created by Ellis Barker on 15/03/2025.
//

import SwiftUI
import Foundation

// Helper functions for badge generation and validation
struct ProfileBadgeHelper {
    // Helper function to generate badge achievement date
    static func generateRandomPastDate(daysAgo: Int) -> Date {
        let now = Date()
        let randomDays = Int.random(in: 1...daysAgo)
        return Calendar.current.date(byAdding: .day, value: -randomDays, to: now) ?? now
    }
    
    // Helper function to generate all badges based on user data
    static func generateBadges(
        userProfile: UserProfile?,
        planCount: Int,
        projectsManager: ProjectsManager = ProjectsManager.shared
    ) -> [BadgeData] {
        // Calculate project-related metrics
        let totalProjects = projectsManager.totalProjects
        let completedProjects = projectsManager.completedProjects
        let totalLogs = projectsManager.totalLogEntries
        
        var badges: [BadgeData] = []
        
        // ANGLE STYLE BADGES - One for each route angle
        for angle in RouteAngle.allCases {
            let completedCount = projectsManager.completedProjectsForAngle(angle)
            let isEarned = completedCount > 0
            
            badges.append(BadgeData(
                name: "\(angle.rawValue) Climber",
                description: "Completed a \(angle.rawValue.lowercased()) route",
                iconName: angle.iconName,
                isEarned: isEarned,
                category: .styles,
                achievementDate: isEarned ? generateRandomPastDate(daysAgo: 30) : nil,
                howToEarn: "Complete a project with the \(angle.rawValue) angle."
            ))
        }
        
        // LENGTH STYLE BADGES - One for each route length
        for length in RouteLength.allCases {
            let completedCount = projectsManager.completedProjectsForLength(length)
            let isEarned = completedCount > 0
            
            badges.append(BadgeData(
                name: "\(length.rawValue) Route Climber",
                description: "Completed a \(length.rawValue.lowercased()) route",
                iconName: length.iconName,
                isEarned: isEarned,
                category: .styles,
                achievementDate: isEarned ? generateRandomPastDate(daysAgo: 30) : nil,
                howToEarn: "Complete a project with the \(length.rawValue) length."
            ))
        }
        
        // HOLD TYPE BADGES - One for each hold type
        for holdType in HoldType.allCases {
            let completedCount = projectsManager.completedProjectsForHoldType(holdType)
            let isEarned = completedCount > 0
            
            badges.append(BadgeData(
                name: "\(holdType.rawValue) Master",
                description: "Completed a route with \(holdType.rawValue.lowercased()) holds",
                iconName: holdType.iconName,
                isEarned: isEarned,
                category: .styles,
                achievementDate: isEarned ? generateRandomPastDate(daysAgo: 30) : nil,
                howToEarn: "Complete a project with \(holdType.rawValue) holds."
            ))
        }
        
        // SPECIALIST BADGES - For completing 3 projects of same category
        
        // Angle Specialist
        let isAngleSpecialist = projectsManager.hasEarnedAngleSpecialistBadge()
        let specialistAngle = projectsManager.specialistAngle()
        
        badges.append(BadgeData(
            name: "Angle Specialist",
            description: specialistAngle != nil ?
                "\(specialistAngle!.rawValue) Specialist - Completed 3+ projects of this angle" :
                "Completed 3+ projects of the same angle",
            iconName: "mountain.2.circle.fill",
            isEarned: isAngleSpecialist,
            category: .styles,
            achievementDate: isAngleSpecialist ? generateRandomPastDate(daysAgo: 15) : nil,
            howToEarn: "Complete at least 3 projects of the same angle."
        ))
        
        // Length Specialist
        let isLengthSpecialist = projectsManager.hasEarnedLengthSpecialistBadge()
        let specialistLength = projectsManager.specialistLength()
        
        badges.append(BadgeData(
            name: "Length Specialist",
            description: specialistLength != nil ?
                "\(specialistLength!.rawValue) Specialist - Completed 3+ projects of this length" :
                "Completed 3+ projects of the same length",
            iconName: "ruler.fill",
            isEarned: isLengthSpecialist,
            category: .styles,
            achievementDate: isLengthSpecialist ? generateRandomPastDate(daysAgo: 15) : nil,
            howToEarn: "Complete at least 3 projects of the same length."
        ))
        
        // Hold Type Specialist
        let isHoldTypeSpecialist = projectsManager.hasEarnedHoldTypeSpecialistBadge()
        let specialistHoldType = projectsManager.specialistHoldType()
        
        badges.append(BadgeData(
            name: "Hold Type Specialist",
            description: specialistHoldType != nil ?
                "\(specialistHoldType!.rawValue) Specialist - Completed 3+ projects with this hold type" :
                "Completed 3+ projects with the same hold type",
            iconName: "hand.raised.circle.fill",
            isEarned: isHoldTypeSpecialist,
            category: .styles,
            achievementDate: isHoldTypeSpecialist ? generateRandomPastDate(daysAgo: 15) : nil,
            howToEarn: "Complete at least 3 projects with the same hold type."
        ))
        
        // PLANS BADGES
        badges.append(BadgeData(
            name: "First Plan",
            description: "Purchased your first training plan",
            iconName: "doc.text.fill",
            isEarned: planCount >= 1,
            category: .plans,
            achievementDate: planCount >= 1 ? generateRandomPastDate(daysAgo: 30) : nil,
            howToEarn: "Purchase your first training plan from the Plans tab."
        ))
        
        badges.append(BadgeData(
            name: "3 Plans",
            description: "Purchased 3 training plans",
            iconName: "doc.on.doc.fill",
            isEarned: planCount >= 3,
            category: .plans,
            achievementDate: planCount >= 3 ? generateRandomPastDate(daysAgo: 20) : nil,
            howToEarn: "Purchase a total of 3 training plans from the Plans tab."
        ))
        
        badges.append(BadgeData(
            name: "5 Plans",
            description: "Purchased 5 training plans",
            iconName: "doc.on.clipboard",
            isEarned: planCount >= 5,
            category: .plans,
            achievementDate: planCount >= 5 ? generateRandomPastDate(daysAgo: 10) : nil,
            howToEarn: "Purchase a total of 5 training plans from the Plans tab."
        ))
        
        badges.append(BadgeData(
            name: "10 Plans",
            description: "Purchased 10 training plans",
            iconName: "books.vertical.fill",
            isEarned: planCount >= 10,
            category: .plans,
            achievementDate: planCount >= 10 ? generateRandomPastDate(daysAgo: 5) : nil,
            howToEarn: "Purchase a total of 10 training plans from the Plans tab."
        ))
        
        badges.append(BadgeData(
            name: "20 Plans",
            description: "Purchased 20 training plans",
            iconName: "magazine.fill",
            isEarned: planCount >= 20,
            category: .plans,
            achievementDate: planCount >= 20 ? generateRandomPastDate(daysAgo: 2) : nil,
            howToEarn: "Purchase a total of 20 training plans from the Plans tab."
        ))
        
        // PROJECT BADGES
        badges.append(BadgeData(
            name: "First Project",
            description: "Added your first climbing project",
            iconName: "flag.fill",
            isEarned: totalProjects >= 1,
            category: .projects,
            achievementDate: totalProjects >= 1 ? generateRandomPastDate(daysAgo: 30) : nil,
            howToEarn: "Add your first climbing project in the Projects tab."
        ))
        
        badges.append(BadgeData(
            name: "5 Projects",
            description: "Added 5 climbing projects",
            iconName: "flag.2.crossed.fill",
            isEarned: totalProjects >= 5,
            category: .projects,
            achievementDate: totalProjects >= 5 ? generateRandomPastDate(daysAgo: 10) : nil,
            howToEarn: "Add a total of 5 climbing projects in the Projects tab."
        ))
        
        badges.append(BadgeData(
            name: "10 Projects",
            description: "Added 10 climbing projects",
            iconName: "flag.2.crossed",
            isEarned: totalProjects >= 10,
            category: .projects,
            achievementDate: totalProjects >= 10 ? generateRandomPastDate(daysAgo: 5) : nil,
            howToEarn: "Add a total of 10 climbing projects in the Projects tab."
        ))
        
        badges.append(BadgeData(
            name: "First Send",
            description: "Completed your first climbing project",
            iconName: "checkmark.seal.fill",
            isEarned: completedProjects >= 1,
            category: .projects,
            achievementDate: completedProjects >= 1 ? generateRandomPastDate(daysAgo: 25) : nil,
            howToEarn: "Mark your first project as sent in the project details view."
        ))
        
        badges.append(BadgeData(
            name: "5 Sends",
            description: "Completed 5 climbing projects",
            iconName: "hand.thumbsup.circle.fill",
            isEarned: completedProjects >= 5,
            category: .projects,
            achievementDate: completedProjects >= 5 ? generateRandomPastDate(daysAgo: 8) : nil,
            howToEarn: "Mark 5 different projects as sent."
        ))
        
        badges.append(BadgeData(
            name: "10 Sends",
            description: "Completed 10 climbing projects",
            iconName: "trophy.circle.fill",
            isEarned: completedProjects >= 10,
            category: .projects,
            achievementDate: completedProjects >= 10 ? generateRandomPastDate(daysAgo: 3) : nil,
            howToEarn: "Mark 10 different projects as sent."
        ))
        
        // PROJECT LOG BADGES
        badges.append(BadgeData(
            name: "First Log",
            description: "Added your first project log entry",
            iconName: "doc.text.fill",
            isEarned: totalLogs >= 1,
            category: .logs,
            achievementDate: totalLogs >= 1 ? generateRandomPastDate(daysAgo: 28) : nil,
            howToEarn: "Add your first log entry to any project in the project details view."
        ))
        
        badges.append(BadgeData(
            name: "10 Logs",
            description: "Added 10 project log entries",
            iconName: "doc.on.doc.fill",
            isEarned: totalLogs >= 10,
            category: .logs,
            achievementDate: totalLogs >= 10 ? generateRandomPastDate(daysAgo: 21) : nil,
            howToEarn: "Add a total of 10 log entries across all your projects."
        ))
        
        badges.append(BadgeData(
            name: "25 Logs",
            description: "Added 25 project log entries",
            iconName: "doc.text.below.ecg",
            isEarned: totalLogs >= 25,
            category: .logs,
            achievementDate: totalLogs >= 25 ? generateRandomPastDate(daysAgo: 14) : nil,
            howToEarn: "Add a total of 25 log entries across all your projects."
        ))
        
        badges.append(BadgeData(
            name: "50 Logs",
            description: "Added 50 project log entries",
            iconName: "book.fill",
            isEarned: totalLogs >= 50,
            category: .logs,
            achievementDate: totalLogs >= 50 ? generateRandomPastDate(daysAgo: 7) : nil,
            howToEarn: "Add a total of 50 log entries across all your projects."
        ))
        
        badges.append(BadgeData(
            name: "100 Logs",
            description: "Added 100 project log entries",
            iconName: "books.vertical.fill",
            isEarned: totalLogs >= 100,
            category: .logs,
            achievementDate: totalLogs >= 100 ? generateRandomPastDate(daysAgo: 2) : nil,
            howToEarn: "Add a total of 100 log entries across all your projects."
        ))
        
        return badges
    }
}
