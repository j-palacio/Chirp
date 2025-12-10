//
//  TrendsModel.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202417.12.2023.
//

import Foundation

// MARK: - Trend (from Supabase)

struct Trend: Codable, Identifiable {
    let id: UUID
    let hashtag: String?
    let title: String?
    let category: String?
    let sourceName: String?
    let sourceUrl: String?
    let imageUrl: String?
    let description: String?
    let postCount: Int
    let isTrending: Bool
    let createdAt: Date
    let updatedAt: Date
    let expiresAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, hashtag, title, category, description
        case sourceName = "source_name"
        case sourceUrl = "source_url"
        case imageUrl = "image_url"
        case postCount = "post_count"
        case isTrending = "is_trending"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case expiresAt = "expires_at"
    }

    /// Display title - uses title if available, otherwise hashtag
    var displayTitle: String {
        title ?? hashtag ?? "Unknown"
    }

    /// Formatted post count (e.g., "78K posts")
    var formattedPostCount: String {
        if postCount >= 1_000_000 {
            return String(format: "%.1fM posts", Double(postCount) / 1_000_000)
        } else if postCount >= 1_000 {
            return String(format: "%.1fK posts", Double(postCount) / 1_000)
        }
        return "\(postCount) posts"
    }

    /// Relative time since created (e.g., "23 hours ago")
    func relativeTimestamp() -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .minute], from: createdAt, to: Date())

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

// MARK: - Trend Insert (for creating new trends)

struct TrendInsert: Codable {
    let hashtag: String?
    let title: String?
    let category: String?
    let sourceName: String?
    let sourceUrl: String?
    let imageUrl: String?
    let description: String?
    let postCount: Int?
    let isTrending: Bool?

    enum CodingKeys: String, CodingKey {
        case hashtag, title, category, description
        case sourceName = "source_name"
        case sourceUrl = "source_url"
        case imageUrl = "image_url"
        case postCount = "post_count"
        case isTrending = "is_trending"
    }
}

// MARK: - Explore Tab Category

enum ExploreCategory: String, CaseIterable {
    case forYou = "For You"
    case trending = "Trending"
    case news = "News"
    case sports = "Sports"
    case entertainment = "Entertainment"
}

// MARK: - Legacy TrendsModel (for backward compatibility with MockTrends)

final class TrendsModel {
    let id: Int
    let category: String
    let trending: Bool
    let title: String
    let tweets: String

    init(id: Int, category: String, trending: Bool, title: String, tweets: String) {
        self.id = id
        self.category = category
        self.trending = trending
        self.title = title
        self.tweets = tweets
    }
}
