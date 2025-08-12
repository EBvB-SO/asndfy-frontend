//
//  APIClient.swift
//  Ascendify
//
//  Created by Ellis Barker on 12/08/2025.
//

import Foundation

enum API {
    // Change to your production API base
    static let baseURL = URL(string: "http://127.0.0.1:8001")!
}

struct AnalyticsAPI {
    static func fetchDashboard(email: String, token: String) async throws -> DashboardDTO {
        let url = API.baseURL.appendingPathComponent("/analytics/\(email)")

        var req = URLRequest(url: url)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(DashboardDTO.self, from: data)
    }
}
