//
//  NetworkManager.swift
//  Ascendify
//
//  Created by Ellis Barker on 17/03/2025.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
    case serverError(String)
    case notFound
}

// For endpoints that legitimately return nothing (204 etc)
struct EmptyResponse: Decodable { }

final class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "http://127.0.0.1:8001"
    private init() {}

    // MARK: - Helpers ----------------------------------------------------------

    private func buildURL(from endpoint: String) -> URL? {
        let trimmed = endpoint.hasPrefix("/") ? String(endpoint.dropFirst()) : endpoint
        let encoded = trimmed
            .split(separator: "/")
            .map { $0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0) }
            .joined(separator: "/")
        return URL(string: "\(baseURL)/\(encoded)")
    }

    private func debugPrintBody(_ data: Data) {
        if let s = String(data: data, encoding: .utf8) {
            print("🔴 Raw response body:\n\(s)")
        } else {
            print("🔴 Raw response body (non‑utf8, \(data.count) bytes)")
        }
    }

    // MARK: - GET --------------------------------------------------------------

    func get<T: Decodable>(endpoint: String) async throws -> T {
        guard let url = buildURL(from: endpoint) else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        request.addAuthHeader()

        let (data, response) = try await URLSession.shared.authenticatedData(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }

        switch http.statusCode {
        case 200:
            do {
                let env = try JSONDecoder().decode(APIEnvelope<T>.self, from: data)
                return env.data
            } catch {
                debugPrintBody(data)
                throw NetworkError.decodingFailed(error)
            }
        case 404:
            throw NetworkError.notFound
        default:
            if let err = try? JSONDecoder().decode([String:String].self, from: data),
               let detail = err["detail"] {
                throw NetworkError.serverError(detail)
            }
            throw NetworkError.serverError("Unknown server error: \(http.statusCode)")
        }
    }

    // MARK: - POST -------------------------------------------------------------

    func post<T: Encodable, U: Decodable>(endpoint: String, body: T) async throws -> U {
        guard let url = buildURL(from: endpoint) else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addAuthHeader()
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.authenticatedData(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }

        switch http.statusCode {
        case 200, 201, 204:
            // Handle empty/204 responses
            if U.self == EmptyResponse.self || data.isEmpty {
                return EmptyResponse() as! U
            }
            do {
                let env = try JSONDecoder().decode(APIEnvelope<U>.self, from: data)
                return env.data
            } catch {
                debugPrintBody(data)
                throw NetworkError.decodingFailed(error)
            }

        case 404:
            throw NetworkError.notFound

        default:
            if let err = try? JSONDecoder().decode([String:String].self, from: data),
               let detail = err["detail"] {
                throw NetworkError.serverError(detail)
            }
            throw NetworkError.serverError("Unknown server error: \(http.statusCode)")
        }
    }

    // MARK: - PUT --------------------------------------------------------------

    func put<T: Encodable, U: Decodable>(endpoint: String, body: T) async throws -> U {
        guard let url = buildURL(from: endpoint) else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addAuthHeader()
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.authenticatedData(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }

        switch http.statusCode {
        case 200, 204:
            if U.self == EmptyResponse.self || data.isEmpty {
                return EmptyResponse() as! U
            }
            do {
                let env = try JSONDecoder().decode(APIEnvelope<U>.self, from: data)
                return env.data
            } catch {
                debugPrintBody(data)
                throw NetworkError.decodingFailed(error)
            }

        case 404:
            throw NetworkError.notFound

        default:
            if let err = try? JSONDecoder().decode([String:String].self, from: data),
               let detail = err["detail"] {
                throw NetworkError.serverError(detail)
            }
            throw NetworkError.serverError("Unknown server error: \(http.statusCode)")
        }
    }

    // MARK: - DELETE -----------------------------------------------------------

    func delete(endpoint: String) async throws {
        guard let url = buildURL(from: endpoint) else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addAuthHeader()

        let (data, response) = try await URLSession.shared.authenticatedData(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }

        switch http.statusCode {
        case 200, 204:
            return
        case 404:
            throw NetworkError.notFound
        default:
            if let err = try? JSONDecoder().decode([String:String].self, from: data),
               let detail = err["detail"] {
                throw NetworkError.serverError(detail)
            }
            debugPrintBody(data)
            throw NetworkError.serverError("Delete failed with status: \(http.statusCode)")
        }
    }
}

extension NetworkManager {
  /// For endpoints that return a raw JSON array, not wrapped in `{ data: … }`
  func getList<T: Decodable>(endpoint: String) async throws -> [T] {
    guard let url = buildURL(from: endpoint) else { throw NetworkError.invalidURL }
    var req = URLRequest(url: url)
    req.addAuthHeader()
    let (data, response) = try await URLSession.shared.authenticatedData(for: req)
    guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
    switch http.statusCode {
    case 200:
      do {
        return try JSONDecoder().decode([T].self, from: data)
      } catch {
        debugPrintBody(data)
        throw NetworkError.decodingFailed(error)
      }
    case 404:
      throw NetworkError.notFound
    default:
      // copy your existing default error logic…
      throw NetworkError.serverError("Status \(http.statusCode)")
    }
  }
}
