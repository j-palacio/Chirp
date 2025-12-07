//
//  ContentModerationService.swift
//  Chirp
//
//  Created by Claude on 07.12.2025.
//

import Foundation

/// Service for content moderation using Google's Perspective API
/// Detects toxicity, identity attacks, threats, and other harmful content
final class ContentModerationService {

    // MARK: - Types

    struct ModerationResult {
        let isApproved: Bool
        let toxicityScore: Double
        let identityAttackScore: Double
        let threatScore: Double
        let insultScore: Double
        let reason: String?

        var shouldFlag: Bool {
            toxicityScore > 0.7 || identityAttackScore > 0.6 || threatScore > 0.5
        }

        var shouldReject: Bool {
            toxicityScore > 0.9 || identityAttackScore > 0.8 || threatScore > 0.7
        }
    }

    struct PerspectiveRequest: Codable {
        let comment: Comment
        let languages: [String]
        let requestedAttributes: [String: AttributeConfig]

        struct Comment: Codable {
            let text: String
        }

        struct AttributeConfig: Codable {
            // Empty config uses defaults
        }
    }

    struct PerspectiveResponse: Codable {
        let attributeScores: [String: AttributeScore]?
        let error: PerspectiveError?

        struct AttributeScore: Codable {
            let summaryScore: SummaryScore

            struct SummaryScore: Codable {
                let value: Double
            }
        }

        struct PerspectiveError: Codable {
            let message: String
        }
    }

    // MARK: - Properties

    private let apiKey: String
    private let baseURL = "https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze"

    // Thresholds for moderation
    private let toxicityThreshold = 0.7
    private let identityAttackThreshold = 0.6
    private let threatThreshold = 0.5

    // MARK: - Singleton

    static let shared = ContentModerationService()

    private init() {
        // Load API key from environment or config
        // For now, using a placeholder - you'll need to add your actual key
        self.apiKey = ProcessInfo.processInfo.environment["PERSPECTIVE_API_KEY"] ?? ""
    }

    // MARK: - Public Methods

    /// Analyze content for harmful material
    func analyzeContent(_ text: String) async throws -> ModerationResult {
        // If no API key, approve by default (for development)
        guard !apiKey.isEmpty else {
            print("Warning: Perspective API key not configured. Skipping moderation.")
            return ModerationResult(
                isApproved: true,
                toxicityScore: 0,
                identityAttackScore: 0,
                threatScore: 0,
                insultScore: 0,
                reason: nil
            )
        }

        // Build request
        let request = PerspectiveRequest(
            comment: .init(text: text),
            languages: ["en"],
            requestedAttributes: [
                "TOXICITY": .init(),
                "IDENTITY_ATTACK": .init(),
                "THREAT": .init(),
                "INSULT": .init()
            ]
        )

        // Create URL request
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw ModerationError.invalidURL
        }
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]

        guard let url = urlComponents.url else {
            throw ModerationError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        // Make request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ModerationError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw ModerationError.apiError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let perspectiveResponse = try JSONDecoder().decode(PerspectiveResponse.self, from: data)

        if let error = perspectiveResponse.error {
            throw ModerationError.perspectiveError(error.message)
        }

        // Extract scores
        let toxicity = perspectiveResponse.attributeScores?["TOXICITY"]?.summaryScore.value ?? 0
        let identityAttack = perspectiveResponse.attributeScores?["IDENTITY_ATTACK"]?.summaryScore.value ?? 0
        let threat = perspectiveResponse.attributeScores?["THREAT"]?.summaryScore.value ?? 0
        let insult = perspectiveResponse.attributeScores?["INSULT"]?.summaryScore.value ?? 0

        // Determine approval
        let shouldReject = toxicity > 0.9 || identityAttack > 0.8 || threat > 0.7
        let shouldFlag = toxicity > toxicityThreshold || identityAttack > identityAttackThreshold || threat > threatThreshold

        var reason: String?
        if shouldReject || shouldFlag {
            var reasons: [String] = []
            if toxicity > toxicityThreshold { reasons.append("toxic content") }
            if identityAttack > identityAttackThreshold { reasons.append("identity-based attack") }
            if threat > threatThreshold { reasons.append("threatening content") }
            reason = reasons.joined(separator: ", ")
        }

        return ModerationResult(
            isApproved: !shouldReject,
            toxicityScore: toxicity,
            identityAttackScore: identityAttack,
            threatScore: threat,
            insultScore: insult,
            reason: reason
        )
    }

    /// Quick check if content is likely safe (for UI feedback)
    func quickCheck(_ text: String) async -> Bool {
        do {
            let result = try await analyzeContent(text)
            return result.isApproved
        } catch {
            // On error, allow the post (will be reviewed)
            return true
        }
    }
}

// MARK: - Errors

enum ModerationError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
    case perspectiveError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from moderation service"
        case .apiError(let code):
            return "API error: \(code)"
        case .perspectiveError(let message):
            return "Moderation error: \(message)"
        }
    }
}
