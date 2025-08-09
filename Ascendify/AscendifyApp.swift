//
//  AscendifyApp.swift
//  Ascendify
//
//  Created by Ellis Barker on 08/02/2025.
//

import SwiftUI

@main
struct AscendifyApp: App {
    @StateObject private var userViewModel = UserViewModel.shared

    init() {
        // Initialize exercise library
        let exerciseLib = ExerciseLib()
        ExerciseLibraryManager.shared.initializeWithLibrary(
            categories: exerciseLib.categories
        )
        _ = ExerciseMatchHelper.shared
        print("Exercise library pre-loaded with \(ExerciseLibraryManager.shared.categories.count) categories")
        for category in ExerciseLibraryManager.shared.categories {
            print("Category: \(category.name) – \(category.exercises.count) exercises")
        }

        // Token refresh on app launch
        Task {
            if UserViewModel.shared.isSignedIn {
                UserViewModel.shared.refreshTokenIfNeeded { refreshed in
                    print("Token refreshed on launch: \(refreshed)")
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if userViewModel.isSignedIn {
                    MainTabView()
                        .onAppear {
                            // Initialize session tracking when user is signed in
                            initializeSessionTracking()
                        }
                } else {
                    SignInView()
                }
            }
            .environmentObject(userViewModel)
            // Handle app lifecycle for data persistence
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.willResignActiveNotification
                )
            ) { _ in
                // Save data when app goes to background
                SessionTrackingManager.shared.saveAllData()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.didBecomeActiveNotification
                )
            ) { _ in
                // Ensure data is accessible when app becomes active
                SessionTrackingManager.shared.ensureLocalDataAccessibility()
                
                // Try to sync if online
                if SessionTrackingManager.shared.networkStatus == .connected {
                    Task {
                        await SessionTrackingManager.shared.forceCompleteSync()
                    }
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.willTerminateNotification
                )
            ) { _ in
                // Final save when app is terminating
                SessionTrackingManager.shared.saveAllData()
            }
        }
    }
    
    // MARK: - Helper Methods
    private func initializeSessionTracking() {
        // Ensure local data is loaded
        SessionTrackingManager.shared.ensureLocalDataAccessibility()
        
        // Start background sync process
        Task {
            // Give the UI a moment to load
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Process any pending updates
            await SessionTrackingManager.shared.forceCompleteSync()
        }
    }
}

// MARK: - Debug Extension
#if DEBUG
extension AscendifyApp {
    // Add debug sync view to your main tab or settings
    static func addDebugView() -> some View {
        NavigationLink("🔧 Sync Debug") {
            SimplifiedSyncDebugView()
        }
    }
}
#endif
