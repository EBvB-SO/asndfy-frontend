//
//  AddProjectView.swift
//  Ascendify
//
//  Created by Ellis Barker on 15/03/2025.
//

import SwiftUI

struct AddProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var projectsManager = ProjectsManager.shared
    
    let userEmail: String
    
    @State private var routeName = ""
    @State private var grade = ""
    @State private var crag = ""
    @State private var description = ""
    
    @State private var selectedAngle: RouteAngle = .vertical
    @State private var selectedLength: RouteLength = .medium
    @State private var selectedHoldType: HoldType = .jugs
    
    @State private var errorMessage: String? = nil
    @State private var isAdding = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HeaderView()
                formContent
            }
            .navigationBarHidden(true)
            .disabled(isAdding)
            .overlay(
                Group {
                    if isAdding {
                        ProgressView("Adding...")
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .shadow(radius: 3)
                    }
                }
            )
        }
    }
    
    private var formContent: some View {
        Form {
            infoSection
            angleSection
            lengthSection
            holdTypeSection
            errorSection
            actionSection
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    @ViewBuilder
    private var infoSection: some View {
        Section(header: Text("Project Information").foregroundColor(.deepPurple)) {
            TextField("Route Name", text: $routeName)
            TextField("Grade", text: $grade)
            TextField("Crag (where is it?)", text: $crag)
            ZStack(alignment: .topLeading) {
                if description.isEmpty {
                    Text("Description (optional)")
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                TextEditor(text: $description)
                    .frame(minHeight: 100)
                    .padding(.horizontal, -4)
            }
        }
    }

    private var angleSection: some View {
        Section(header: Text("Route Angle").foregroundColor(.deepPurple)) {
            Picker("Select Angle", selection: $selectedAngle) {
                ForEach(RouteAngle.allCases, id: \.self) { angle in
                    HStack {
                        Image(systemName: angle.iconName)
                        Text(angle.rawValue)
                    }
                    .tag(angle)
                }
            }
            .pickerStyle(MenuPickerStyle())
            HStack {
                Image(systemName: selectedAngle.iconName)
                Text(selectedAngle.rawValue)
            }
            .foregroundColor(.gray)
            .padding(.vertical, 4)
        }
    }

    private var lengthSection: some View {
        Section(header: Text("Route Length").foregroundColor(.deepPurple)) {
            Picker("Select Length", selection: $selectedLength) {
                ForEach(RouteLength.allCases, id: \.self) { length in
                    HStack {
                        Image(systemName: length.iconName)
                        Text(length.rawValue)
                    }
                    .tag(length)
                }
            }
            .pickerStyle(MenuPickerStyle())
            HStack {
                Image(systemName: selectedLength.iconName)
                Text(selectedLength.rawValue)
            }
            .foregroundColor(.gray)
            .padding(.vertical, 4)
        }
    }

    private var holdTypeSection: some View {
        Section(header: Text("Hold Type").foregroundColor(.deepPurple)) {
            Picker("Select Hold Type", selection: $selectedHoldType) {
                ForEach(HoldType.allCases, id: \.self) { holdType in
                    HStack {
                        Image(systemName: holdType.iconName)
                        Text(holdType.rawValue)
                    }
                    .tag(holdType)
                }
            }
            .pickerStyle(MenuPickerStyle())
            HStack {
                Image(systemName: selectedHoldType.iconName)
                Text(selectedHoldType.rawValue)
            }
            .foregroundColor(.gray)
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let error = errorMessage {
            Section {
                Text(error)
                    .foregroundColor(.red)
            }
        }
    }

    private var actionSection: some View {
        Section {
            Button(action: addProject) {
                Text("Add Project")
                    .foregroundColor(.offWhite)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(Color.ascendGreen)
            .cornerRadius(10)
            .disabled(isAdding)
        }
    }
    
    private func addProject() {
        errorMessage = nil
        guard !routeName.isEmpty else { errorMessage = "Please enter a route name"; return }
        guard !grade.isEmpty else { errorMessage = "Please enter a grade"; return }
        guard !crag.isEmpty else { errorMessage = "Please enter a crag name"; return }
        
        isAdding = true
        Task { await performAdd() }
    }

    @MainActor
    private func performAdd() async {
        await projectsManager.addProject(
            routeName: routeName,
            grade: grade,
            crag: crag,
            description: description,
            routeAngle: selectedAngle,
            routeLength: selectedLength,
            holdType: selectedHoldType
        )
        
        if let error = projectsManager.error {
            errorMessage = error
            isAdding = false
            return
        }
        
        isAdding = false
        dismiss()
    }
}
