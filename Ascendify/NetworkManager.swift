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

struct EmptyResponse: Decodable {}

final class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "http://127.0.0.1:8001"
    private init() {}
    
    private func buildURL(from endpoint: String) -> URL? {
        let trimmed = endpoint.hasPrefix("/") ? String(endpoint.dropFirst()) : endpoint
        let encoded = trimmed
            .split(separator: "/")
            .map { $0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0) }
            .joined(separator: "/")
        return URL(string: "\(baseURL)/\(encoded)")
    }
    
    // GET – expect a top‑level { "data": … } envelope
    func get<T: Decodable>(endpoint: String) async throws -> T {
        guard let url = buildURL(from: endpoint) else { throw NetworkError.invalidURL }
        
        var request = URLRequest(url: url)
        // Add the auth header on the main actor
        await MainActor.run {
            request.addAuthHeader()
        }
        
        let (data, response) = try await URLSession.shared.authenticatedData(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        
        switch http.statusCode {
        case 200:
            do {
                let envelope = try JSONDecoder().decode(APIEnvelope<T>.self, from: data)
                return envelope.data
            } catch {
                throw NetworkError.decodingFailed(error)
            }
        case 404:
            throw NetworkError.notFound
        default:
            // Try to extract a “detail” message from the body
            if let err = try? JSONDecoder().decode([String: String].self, from: data),
               let detail = err["detail"] {
                throw NetworkError.serverError(detail)
            }
            throw NetworkError.serverError("Unknown server error: \(http.statusCode)")
        }
    }
    
    // POST – encode an Encodable body and decode an envelope into U
    func post<T: Encodable, U: Decodable>(endpoint: String, body: T) async throws -> U {
        guard let url = buildURL(from: endpoint) else { throw NetworkError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        await MainActor.run {
            request.addAuthHeader()
        }
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.authenticatedData(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        
        switch http.statusCode {
        case 200, 201, 204:
            // If the caller’s U is EmptyResponse or the body is empty, just return an empty response
            if U.self == EmptyResponse.self || data.isEmpty {
                return EmptyResponse() as! U
            }
            do {
                let env = try JSONDecoder().decode(APIEnvelope<U>.self, from: data)
                return env.data
            } catch {
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
    
    // PUT – encode body and decode a response envelope
    func put<T: Encodable, U: Decodable>(endpoint: String, body: T) async throws -> U {
        guard let url = buildURL(from: endpoint) else { throw NetworkError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Add auth header safely on the main actor
        await MainActor.run {
            request.addAuthHeader()
        }
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
    
    // DELETE – no request body, no response body
    func delete(endpoint: String) async throws {
        guard let url = buildURL(from: endpoint) else { throw NetworkError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        await MainActor.run {
            request.addAuthHeader()
        }
        
        let (data, response) = try await URLSession.shared.authenticatedData(for: request)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
        
        switch http.statusCode {
        case 200, 204:
            return                           // success, no return value
        case 404:
            throw NetworkError.notFound
        default:
            if let err = try? JSONDecoder().decode([String:String].self, from: data),
               let detail = err["detail"] {
                throw NetworkError.serverError(detail)
            }
            throw NetworkError.serverError("Delete failed with status: \(http.statusCode)")
        }
    }
    
    // GET list – decode an array directly (no { data: … } wrapper)
    func getList<T: Decodable>(endpoint: String) async throws -> [T] {
        guard let url = buildURL(from: endpoint) else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        // Build a new request with the auth header on the main actor
        let headerized: URLRequest = await MainActor.run {
            var r = request
            r.addAuthHeader()
            return r
        }

        let (data, response) = try await URLSession.shared.authenticatedData(for: headerized)
        guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }

        switch http.statusCode {
        case 200:
            do { return try JSONDecoder().decode([T].self, from: data) }
            catch { throw NetworkError.decodingFailed(error) }
        case 404:
            throw NetworkError.notFound
        default:
            throw NetworkError.serverError("Status \(http.statusCode)")
        }
    }
}
