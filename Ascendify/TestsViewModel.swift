//
//  TestsViewModel.swift
//  Ascendify
//
//  Created by Ellis Barker on 13/08/2025.
//

import Foundation
import SwiftUI

// MARK: - Decoders

private extension JSONDecoder {
    static func resultsDecoder() -> JSONDecoder {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let s = try container.decode(String.self)

            // Try date-only (UTC, POSIX)
            let df = DateFormatter()
            df.calendar = .init(identifier: .iso8601)
            df.locale   = .init(identifier: "en_US_POSIX")
            df.timeZone = TimeZone(secondsFromGMT: 0)
            df.dateFormat = "yyyy-MM-dd"
            if let d = df.date(from: s) { return d }

            // Fallback to full ISO8601
            if let d = ISO8601DateFormatter().date(from: s) { return d }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unrecognized date format: \(s)"
            )
        }

        dec.keyDecodingStrategy = .convertFromSnakeCase   // 👈 ADD THIS LINE

        return dec
    }
}


// MARK: - Networking errors

enum TestsNetworkError: LocalizedError {
    case badURL
    case badResponse(status: Int)
    case noData
    case decodingFailed(underlying: Error)
    case encodingFailed(underlying: Error)
    case transport(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .badURL:                        return "Invalid URL."
        case .badResponse(let status):       return "Server returned status \(status)."
        case .noData:                        return "Empty response."
        case .decodingFailed(let e):         return "Failed to decode response: \(e.localizedDescription)"
        case .encodingFailed(let e):         return "Failed to encode payload: \(e.localizedDescription)"
        case .transport(let e):              return "Network error: \(e.localizedDescription)"
        }
    }
}

// MARK: - ViewModel

@MainActor
final class TestsViewModel: ObservableObject {
    static let shared = TestsViewModel()
    private init() {}

    // Published state
    @Published var tests: [TestDefinition] = []
    @Published var resultsByTest: [Int: [TestResult]] = [:]
    @Published var errorMessage: String?

    // MARK: Configuration

    /// Base URL for the API. In production, consider moving to a Config plist/xcconfig.
    private var baseURL: String {
        // For local dev:
        "http://127.0.0.1:8001"
    }

    /// Shared URLSession with a sane timeout.
    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 20
        cfg.timeoutIntervalForResource = 40
        return URLSession(configuration: cfg)
    }()

    // MARK: Public API

    /// Load all test definitions.
    func loadTests() async {
        guard let url = URL(string: "\(baseURL)/tests/") else {
            errorMessage = TestsNetworkError.badURL.localizedDescription
            return
        }

        do {
            let (data, response) = try await session.data(from: url)
            try Self.assertOK(response)

            let decoder = JSONDecoder() // definitions don’t need custom date handling
            let decoded = try decoder.decode([TestDefinition].self, from: data)
            tests = decoded
        } catch let e as TestsNetworkError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = TestsNetworkError.transport(underlying: error).localizedDescription
        }
    }

    /// Load results for a given test for a specific user.
    func loadResults(for test: TestDefinition, userEmail: String, token: String) async {
        let encodedEmail = userEmail.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? userEmail
        guard let url = URL(string: "\(baseURL)/tests/users/\(encodedEmail)/\(test.id)/results") else { return }

        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            // Handle empty body gracefully
            if data.isEmpty {
                self.resultsByTest[test.id] = []
                return
            }

            let decoder = JSONDecoder.resultsDecoder()
            let decoded = try decoder.decode([TestResult].self, from: data)
            self.resultsByTest[test.id] = decoded
        } catch {
            errorMessage = "Failed to load results: \(error.localizedDescription)"
        }
    }

    /// Submit a new result and refresh the list for that test.
    func submitResult(
        for test: TestDefinition,
        userEmail: String,
        token: String,
        value: Double,
        date: Date,
        notes: String?
    ) async throws {
        let encodedEmail = userEmail.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? userEmail
        guard let url = URL(string: "\(baseURL)/tests/users/\(encodedEmail)/\(test.id)/results") else {
            throw TestsNetworkError.badURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Backend expects DATE-ONLY ("yyyy-MM-dd")
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .iso8601)
        df.locale   = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd"

        struct NewResultPayload: Encodable {
            let date: String
            let value: Double
            let notes: String
        }

        let payload = NewResultPayload(
            date: df.string(from: date),
            value: value,
            notes: notes ?? ""
        )

        do {
            req.httpBody = try JSONEncoder().encode(payload)
        } catch {
            throw TestsNetworkError.encodingFailed(underlying: error)
        }

        do {
            let (_, response) = try await session.data(for: req)
            try Self.assertOK(response)

            // Refresh results so UI reflects the new entry
            try await refreshResults(for: test, userEmail: userEmail, token: token)
        } catch let e as TestsNetworkError {
            throw e
        } catch {
            throw TestsNetworkError.transport(underlying: error)
        }
    }

    // MARK: Helpers

    /// Convenience to reload results and surface any error in `errorMessage`.
    func refreshResults(for test: TestDefinition, userEmail: String, token: String) async throws {
        let encodedEmail = userEmail.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? userEmail
        guard let url = URL(string: "\(baseURL)/tests/users/\(encodedEmail)/\(test.id)/results") else {
            throw TestsNetworkError.badURL
        }

        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await session.data(for: req)
            try Self.assertOK(response)

            // Handle an empty body gracefully; treat it as “no results”
            if data.isEmpty {
                resultsByTest[test.id] = []
                return
            }

            let decoder = JSONDecoder.resultsDecoder()
            let decoded = try decoder.decode([TestResult].self, from: data)
            resultsByTest[test.id] = decoded
        } catch let e as TestsNetworkError {
            errorMessage = e.localizedDescription
            throw e
        } catch {
            let wrapped = TestsNetworkError.transport(underlying: error)
            errorMessage = wrapped.localizedDescription
            throw wrapped
        }
    }


    /// Throws if the HTTPURLResponse is not in the 2xx range.
    private static func assertOK(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw TestsNetworkError.badResponse(status: -1)
        }
        guard (200...299).contains(http.statusCode) else {
            throw TestsNetworkError.badResponse(status: http.statusCode)
        }
    }
}
