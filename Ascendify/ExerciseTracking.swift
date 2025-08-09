//
//  ExerciseTracking.swift
//  Ascendify
//
//  Created by Ellis Barker on 20/04/2025.
//

import Foundation

/// Represents user progress tracking for each individual exercise
struct ExerciseTracking: Identifiable, Codable, Equatable {
    let id: UUID
    let planId: String
    let sessionId: UUID
    let exerciseId: UUID
    let date: Date
    var notes: String

    // New: extract the legacy key (if present) from the notes
    var legacyKey: String? {
        let pattern = #"\[KEY:([^\]]+)\]"#
        if let range = notes.range(of: pattern, options: .regularExpression) {
            let match = String(notes[range])
            return match
                .replacingOccurrences(of: "[KEY:", with: "")
                .replacingOccurrences(of: "]", with: "")
        }
        return nil
    }
    
    // Add these new fields for sync status
    var isSynced: Bool = false
    var lastSyncAttempt: Date? = nil
    var syncError: String? = nil
    
    // MARK: - Initializers
    init(planId: String, sessionId: UUID, exerciseId: UUID, date: Date, notes: String) {
        self.id = UUID()
        self.planId = planId
        self.sessionId = sessionId
        self.exerciseId = exerciseId
        self.date = date
        self.notes = notes
        self.isSynced = false
        self.lastSyncAttempt = nil
        self.syncError = nil
    }
    
    // Preserve ID for updates
    init(preservingId id: UUID, planId: String, sessionId: UUID, exerciseId: UUID, date: Date, notes: String) {
        self.id = id
        self.planId = planId
        self.sessionId = sessionId
        self.exerciseId = exerciseId
        self.date = date
        self.notes = notes
        self.isSynced = false
        self.lastSyncAttempt = nil
        self.syncError = nil
    }
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id, planId, sessionId, exerciseId, date, notes, isSynced, lastSyncAttempt, syncError
    }
    
    // MARK: - Custom Encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id.uuidString, forKey: .id)
        try container.encode(planId, forKey: .planId)
        try container.encode(sessionId.uuidString, forKey: .sessionId)
        try container.encode(exerciseId.uuidString, forKey: .exerciseId)
        try container.encode(date, forKey: .date)
        try container.encode(notes, forKey: .notes)
        try container.encode(isSynced, forKey: .isSynced)
        try container.encode(lastSyncAttempt, forKey: .lastSyncAttempt)
        try container.encode(syncError, forKey: .syncError)
    }
    
    // MARK: - Custom Decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle UUID decoding - accept either UUID or String
        if let idString = try? container.decode(String.self, forKey: .id) {
            self.id = UUID(uuidString: idString) ?? UUID()
        } else {
            self.id = try container.decode(UUID.self, forKey: .id)
        }
        
        self.planId = try container.decode(String.self, forKey: .planId)
        
        // Handle sessionId UUID decoding
        if let sessionIdString = try? container.decode(String.self, forKey: .sessionId) {
            self.sessionId = UUID(uuidString: sessionIdString) ?? UUID()
        } else {
            self.sessionId = try container.decode(UUID.self, forKey: .sessionId)
        }
        
        // Handle exerciseId UUID decoding
        if let exerciseIdString = try? container.decode(String.self, forKey: .exerciseId) {
            self.exerciseId = UUID(uuidString: exerciseIdString) ?? UUID()
        } else {
            self.exerciseId = try container.decode(UUID.self, forKey: .exerciseId)
        }
        
        self.date = try container.decode(Date.self, forKey: .date)
        self.notes = try container.decode(String.self, forKey: .notes)
        self.isSynced = try container.decodeIfPresent(Bool.self, forKey: .isSynced) ?? false
        self.lastSyncAttempt = try container.decodeIfPresent(Date.self, forKey: .lastSyncAttempt)
        self.syncError = try container.decodeIfPresent(String.self, forKey: .syncError)
    }
}
