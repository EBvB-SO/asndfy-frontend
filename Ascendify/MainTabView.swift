//
//  MainTabView.swift
//  Ascendify
//
//  Created by Ellis Barker on 08/02/2025.
//

import SwiftUI

enum MainTab: Int, Hashable {
    case profile = 0
    case plans
    case projects
    case diary
    case data
}

struct MainTabView: View {
    @EnvironmentObject var userViewModel: UserViewModel

    // selection + a resettable path for the Profile tab
    @State private var selected: MainTab = .profile
    @State private var profilePath = NavigationPath()

    var body: some View {
        ZStack {
            TabView(selection: $selected) {

                // PROFILE — use NavigationStack so we can pop programmatically
                NavigationStack(path: $profilePath) {
                    ProfileView()
                        .navigationBarHidden(true)
                }
                .tabItem { Label("Profile", systemImage: "person.circle") }
                .tag(MainTab.profile)

                // PLANS
                NavigationView { PlansView() }
                    .tabItem { Label("Plans", systemImage: "doc.text") }
                    .tag(MainTab.plans)

                // PROJECTS
                NavigationView { ProjectsView() }
                    .tabItem { Label("Projects", systemImage: "flag.fill") }
                    .tag(MainTab.projects)

                // DIARY
                NavigationView { DiaryView() }
                    .tabItem { Label("Diary", systemImage: "calendar") }
                    .tag(MainTab.diary)

                // DATA
                NavigationView { DataView() }
                    .tabItem { Label("Data", systemImage: "chart.bar.fill") }
                    .tag(MainTab.data)
            }
            .accentColor(.teal)

            // Invisible listener that fires even when the same tab is tapped again
            TabBarReselectReader(selectedIndex: Binding(
                get: { selected.rawValue },
                set: { newValue in selected = MainTab(rawValue: newValue) ?? .profile }
            )) { index in
                // If Profile tab is tapped (including re-taps), pop to root
                if index == MainTab.profile.rawValue {
                    profilePath = NavigationPath()
                }
            }
            .allowsHitTesting(false) // ensure this view doesn't intercept touches
            .frame(width: 0, height: 0)
        }
    }
}
