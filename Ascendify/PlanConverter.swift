//
//  PlanConverter.swift
//  Ascendify
//
//  Created by Ellis Barker on 09/03/2025.
//

import Foundation

/// Converts from your server's phase-based JSON structure into the SwiftUI `PlanModel`
/// that your app's UI actually needs.
class PlanConverter {
    
    /// Matches the raw, phase-based JSON your backend sends,
    /// including the coach’s overview texts and detailed phases.
    struct PhaseBasedPlan: Codable {
        let routeOverview: String?
        let trainingOverview: String?
        let phases: [Phase]

        enum CodingKeys: String, CodingKey {
            case routeOverview    = "route_overview"
            case trainingOverview = "training_overview"
            case phases
        }
        
        struct Phase: Codable {
            let phaseName: String
            let description: String
            let weeklySchedule: [DaySchedule]

            enum CodingKeys: String, CodingKey {
                case phaseName      = "phase_name"
                case description
                case weeklySchedule = "weekly_schedule"
            }
        }
        
        struct DaySchedule: Codable {
            let day: String
            let focus: String
            let details: String
        }
    }
    
    /// Convert from the PhaseBasedPlan model (matching server JSON)
    /// into your final `PlanModel`.
    static func convertToUIModel(
        phasePlan: PhaseBasedPlan,
        routeName: String,
        grade: String,
        previewRouteOverview: String? = nil,
        previewTrainingOverview: String? = nil
    ) -> PlanModel {
        var weeks: [PlanWeek] = []
        
        // Use preview overviews if available
        let routeOverview = previewRouteOverview ?? phasePlan.routeOverview ?? "Training plan for \(routeName)"
        let trainingOverview = previewTrainingOverview ?? phasePlan.trainingOverview ?? "Structured training approach"
        
        // Convert each Phase into a PlanWeek
        for phase in phasePlan.phases {
            // Convert each DaySchedule into a PlanSession
            let sessions: [PlanSession] = phase.weeklySchedule.map { day in
                // Break out the "details" string into warm-up / main / cool-down
                let parts = parseWorkoutDetails(day.details)
                
                // The main workout is a single PlanExercise with a type inferred from the focus/details
                let mainExercise = PlanExercise(
                    type: inferExerciseType(day.focus, day.details),
                    title: day.focus,
                    description: parts.mainWorkout
                )
                
                return PlanSession(
                    // Combine day + focus as the sessionTitle
                    sessionTitle: "\(day.day): \(day.focus)",
                    
                    // Warm-up is an array of strings
                    warmUp: parts.warmUp,
                    
                    // mainWorkout is an array of PlanExercise
                    mainWorkout: [mainExercise],
                    
                    // Cool-down is also an array of strings
                    coolDown: parts.coolDown
                )
            }
            
            // Create a week with title = phaseName
            let week = PlanWeek(
                title: phase.phaseName,
                sessions: sessions
            )
            
            weeks.append(week)
        }
        
        // Finally, build and return the PlanModel
        return PlanModel(
            routeOverview: routeOverview,
            trainingOverview: trainingOverview,
            weeks: weeks
        )
    }
    
    /// Parses a big "details" string into separate warmUp lines, mainWorkout text, and coolDown lines.
    private static func parseWorkoutDetails(_ details: String) -> (
        warmUp: [String],
        mainWorkout: String,
        coolDown: [String]
    ) {
        var warmUp: [String] = []
        var mainWorkout = details
        var coolDown: [String] = []
        
        // Split by lines and trim
        let lines = details
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        var currentSection = "main"
        var mainLines: [String] = []
        
        for line in lines {
            let lower = line.lowercased()
            if lower.contains("warm-up") || lower.contains("warm up") {
                currentSection = "warmup"
                continue
            } else if lower.contains("cool-down") || lower.contains("cool down") {
                currentSection = "cooldown"
                continue
            } else if line.isEmpty {
                continue
            }
            
            switch currentSection {
            case "warmup":
                warmUp.append(stripLeadingBullets(line))
            case "cooldown":
                coolDown.append(stripLeadingBullets(line))
            default:
                mainLines.append(line)
            }
        }
        
        if !mainLines.isEmpty {
            mainWorkout = mainLines.joined(separator: "\n")
        }
        
        // Provide defaults if none found
        if warmUp.isEmpty {
            warmUp = ["General warm-up (5-10 minutes)", "Dynamic stretching"]
        }
        if coolDown.isEmpty {
            coolDown = ["Light stretching", "Cool-down exercises"]
        }
        
        return (warmUp, mainWorkout, coolDown)
    }
    
    /// Removes leading bullets or dashes (like "• " or "- ") if present
    private static func stripLeadingBullets(_ line: String) -> String {
        return line.replacingOccurrences(
            of: #"^[•\-\*]\s*"#,
            with: "",
            options: .regularExpression
        )
    }
    
    /// Infers the exercise type from the focus and details
    private static func inferExerciseType(
        _ focus: String,
        _ details: String
    ) -> String {
        let combined = (focus + " " + details).lowercased()
        
        if combined.contains("fingerboard") || combined.contains("hangboard") {
            return "fingerboard"
        } else if combined.contains("campus") {
            return "campus"
        } else if combined.contains("power") && combined.contains("endurance") {
            return "power-endurance"
        } else if combined.contains("power") {
            return "power"
        } else if combined.contains("strength") {
            return "strength"
        } else if combined.contains("endurance") {
            return "endurance"
        } else if combined.contains("technique") || combined.contains("skill") {
            return "technique"
        } else if combined.contains("core") || combined.contains("abs") {
            return "core"
        } else if combined.contains("rest") || combined.contains("recovery") {
            return "rest"
        } else if combined.contains("stretching") || combined.contains("mobility") {
            return "mobility"
        } else {
            return "climbing"
        }
    }
}
