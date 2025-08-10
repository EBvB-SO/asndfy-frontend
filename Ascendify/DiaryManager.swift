//
//  DiaryManager.swift
//  Ascendify
//
//  Created by Ellis Barker on 10/08/2025.
//

import Foundation
import SwiftUI

final class DiaryManager: ObservableObject {
    static let shared = DiaryManager()

    @Published private(set) var dailyNotes: [DailyNoteModel] = []
    private var currentEmail: String?

    // Call when user changes (sign-in/sign-out)
    func setCurrentUser(email: String) {
        currentEmail = email
        // reset in-memory immediately so UI doesn’t show old notes
        dailyNotes = []
        loadFromStorage()
        // optionally: also fetch from server here
        // fetchFromServer()
    }

    func clear() {
        dailyNotes = []
        guard let email = currentEmail else { return }
        let key = UserScopedStorage.key("daily_notes", email: email)
        UserDefaults.standard.removeObject(forKey: key)
    }

    // MARK: - Storage
    private func storageKey() -> String? {
        guard let email = currentEmail else { return nil }
        return UserScopedStorage.key("daily_notes", email: email)
    }

    func loadFromStorage() {
        guard let key = storageKey() else { return }
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([DailyNoteModel].self, from: data) {
            self.dailyNotes = decoded
        } else {
            self.dailyNotes = []
        }
    }

    func saveToStorage() {
        guard let key = storageKey() else { return }
        if let data = try? JSONEncoder().encode(dailyNotes) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
