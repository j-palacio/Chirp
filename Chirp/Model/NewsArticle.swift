//
//  NewsArticle.swift
//  Chirp
//
//  Created by Juan Palacio on 10.12.2025.
//

import Foundation

// MARK: - NewsAPI Response

struct NewsAPIResponse: Codable {
    let status: String
    let totalResults: Int
    let articles: [NewsAPIArticle]
}

// MARK: - NewsAPI Article (from external API)

struct NewsAPIArticle: Codable, Identifiable {
    let source: NewsSource
    let author: String?
    let title: String
    let description: String?
    let url: String
    let urlToImage: String?
    let publishedAt: String
    let content: String?

    var id: String { url }

    struct NewsSource: Codable {
        let id: String?
        let name: String
    }

    /// Convert publishedAt string to Date
    var publishedDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: publishedAt) {
            return date
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: publishedAt)
    }

    /// Relative time since published (e.g., "23 hours ago")
    func relativeTimestamp() -> String {
        guard let date = publishedDate else { return "" }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: Date())

        if let days = components.day, days > 0 {
            return "\(days) day\(days > 1 ? "s" : "") ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "") ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes) min ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - News Article (from Supabase cache)

struct NewsArticle: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String?
    let sourceName: String?
    let sourceUrl: String
    let imageUrl: String?
    let category: String
    let publishedAt: Date?
    let fetchedAt: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, description, category
        case sourceName = "source_name"
        case sourceUrl = "source_url"
        case imageUrl = "image_url"
        case publishedAt = "published_at"
        case fetchedAt = "fetched_at"
        case createdAt = "created_at"
    }

    /// Relative time since published (e.g., "23 hours ago")
    func relativeTimestamp() -> String {
        guard let date = publishedAt else { return "" }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: Date())

        if let days = components.day, days > 0 {
            return "\(days) day\(days > 1 ? "s" : "") ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours > 1 ? "s" : "") ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes) min ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - News Article Insert (for caching to Supabase)

struct NewsArticleInsert: Codable {
    let title: String
    let description: String?
    let sourceName: String?
    let sourceUrl: String
    let imageUrl: String?
    let category: String
    let publishedAt: Date?

    enum CodingKeys: String, CodingKey {
        case title, description, category
        case sourceName = "source_name"
        case sourceUrl = "source_url"
        case imageUrl = "image_url"
        case publishedAt = "published_at"
    }
}
