//
//  MainTabView.swift
//  Ascendify
//
//  Created by Ellis Barker on 08/02/2025.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
        TabView {
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle")
            }
            
            NavigationView {
                PlansView()
            }
            .tabItem {
                Label("Plans", systemImage: "doc.text")
            }
            
            NavigationView {
                ProjectsView()
            }
            .tabItem {
                Label("Projects", systemImage: "flag.fill")
            }
            
            NavigationView {
                DiaryView()
            }
            .tabItem {
                Label("Diary", systemImage: "calendar")
            }
            
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .accentColor(.teal)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
