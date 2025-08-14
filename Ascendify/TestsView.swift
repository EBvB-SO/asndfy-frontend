//
//  TestsView.swift
//  Ascendify
//
//  Created by Ellis Barker on 13/08/2025.
//

import SwiftUI
import Charts

struct TestsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @ObservedObject private var vm = TestsViewModel.shared

    @State private var selectedTest: TestDefinition?

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            content
        }
        .sheet(item: $selectedTest) { test in
            TestDetailView(test: test)
                .environmentObject(userViewModel)
        }
        .task {
            await vm.loadTests()
            if let email = userViewModel.userProfile?.email,
               let token = userViewModel.accessToken, !token.isEmpty {
                for test in vm.tests {
                    await vm.loadResults(for: test, userEmail: email, token: token)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Assessments")
                    .font(.headline)
                    .foregroundColor(.tealBlue)
                    .padding(.horizontal)

                if let error = vm.errorMessage {
                    Text(error).foregroundColor(.red).padding(.horizontal)
                }

                VStack(spacing: 12) {
                    ForEach(vm.tests, id: \.id) { test in
                        TestRowView(
                            title: test.name,
                            subtitle: latestSubtitle(for: test),
                            action: { selectedTest = test }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
    }

    private func latestSubtitle(for test: TestDefinition) -> String {
        if let latest = vm.resultsByTest[test.id]?.last {
            let unit = test.unit ?? ""
            return "Latest: \(latest.value) \(unit)"
        } else {
            return "No results"
        }
    }
}

private struct TestRowView: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline).foregroundColor(.primary)
                    Text(subtitle).font(.subheadline).foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.gray)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
