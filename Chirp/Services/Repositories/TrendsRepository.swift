//
//  TrendsRepository.swift
//  Chirp
//
//  Created by Juan Palacio on 10.12.2025.
//

import Foundation
import Supabase

/// Repository for trend-related database operations
final class TrendsRepository {
    private let supabase = SupabaseManager.shared.client

    // MARK: - Fetch Trends

    /// Fetch all trending topics ordered by post count
    func fetchTrends(limit: Int = 20) async throws -> [Trend] {
        try await supabase
            .from("trends")
            .select("*")
            .eq("is_trending", value: true)
            .order("post_count", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// Fetch trends by category
    func fetchTrendsByCategory(category: String, limit: Int = 10) async throws -> [Trend] {
        try await supabase
            .from("trends")
            .select("*")
            .eq("category", value: category)
            .order("post_count", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// Fetch trending hashtags only
    func fetchTrendingHashtags(limit: Int = 10) async throws -> [Trend] {
        try await supabase
            .from("trends")
            .select("*")
            .eq("is_trending", value: true)
            .not("hashtag", operator: .is, value: "null")
            .order("post_count", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// Fetch news trends (trends with source_url)
    func fetchNewsTrends(limit: Int = 10) async throws -> [Trend] {
        try await supabase
            .from("trends")
            .select("*")
            .not("source_url", operator: .is, value: "null")
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    // MARK: - Fetch News Articles (cached from NewsAPI)

    /// Fetch cached news articles by category
    func fetchNewsArticles(category: String = "News", limit: Int = 20) async throws -> [NewsArticle] {
        try await supabase
            .from("news_articles")
            .select("*")
            .eq("category", value: category)
            .order("published_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// Fetch all cached news articles
    func fetchAllNewsArticles(limit: Int = 50) async throws -> [NewsArticle] {
        try await supabase
            .from("news_articles")
            .select("*")
            .order("published_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    // MARK: - Create/Update Trends

    /// Insert a new trend
    func insertTrend(_ trend: TrendInsert) async throws -> Trend {
        try await supabase
            .from("trends")
            .insert(trend)
            .select()
            .single()
            .execute()
            .value
    }

    /// Insert or update a hashtag trend (upsert)
    func upsertHashtagTrend(hashtag: String, category: String? = nil) async throws {
        let trend = TrendInsert(
            hashtag: hashtag,
            title: nil,
            category: category,
            sourceName: nil,
            sourceUrl: nil,
            imageUrl: nil,
            description: nil,
            postCount: 1,
            isTrending: true
        )

        try await supabase
            .from("trends")
            .upsert(trend, onConflict: "hashtag")
            .execute()
    }

    /// Increment post count for a trend
    func incrementTrendCount(trendId: UUID) async throws {
        try await supabase
            .rpc("increment_trend_count", params: ["trend_id": trendId])
            .execute()
    }

    // MARK: - Cache News Articles

    /// Cache news articles from NewsAPI
    func cacheNewsArticles(_ articles: [NewsAPIArticle], category: String = "News") async throws {
        let inserts = articles.map { article in
            NewsArticleInsert(
                title: article.title,
                description: article.description,
                sourceName: article.source.name,
                sourceUrl: article.url,
                imageUrl: article.urlToImage,
                category: category,
                publishedAt: article.publishedDate
            )
        }

        // Delete old articles in this category first
        try await supabase
            .from("news_articles")
            .delete()
            .eq("category", value: category)
            .execute()

        // Insert new articles
        try await supabase
            .from("news_articles")
            .insert(inserts)
            .execute()
    }

    // MARK: - Search

    /// Search trends by title or hashtag
    func searchTrends(query: String, limit: Int = 20) async throws -> [Trend] {
        try await supabase
            .from("trends")
            .select("*")
            .or("hashtag.ilike.%\(query)%,title.ilike.%\(query)%")
            .order("post_count", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    // MARK: - Delete Expired

    /// Delete expired trends
    func deleteExpiredTrends() async throws {
        try await supabase
            .from("trends")
            .delete()
            .lt("expires_at", value: ISO8601DateFormatter().string(from: Date()))
            .execute()
    }
}

// MARK: - Mock Data for Development

extension TrendsRepository {
    /// Get mock trends for development/testing
    static func getMockTrends() -> [Trend] {
        let now = Date()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return [
            createMockTrend(
                hashtag: "#LaborRights",
                title: nil,
                category: "Trending",
                postCount: 45200,
                createdAt: now.addingTimeInterval(-3600)
            ),
            createMockTrend(
                hashtag: "#ClimateAction",
                title: nil,
                category: "Trending",
                postCount: 32100,
                createdAt: now.addingTimeInterval(-7200)
            ),
            createMockTrend(
                hashtag: nil,
                title: "Workers Strike for Fair Wages",
                category: "News",
                sourceName: "Reuters",
                sourceUrl: "https://reuters.com/example",
                postCount: 78000,
                createdAt: now.addingTimeInterval(-1800)
            ),
            createMockTrend(
                hashtag: "#MedicareForAll",
                title: nil,
                category: "Politics",
                postCount: 28500,
                createdAt: now.addingTimeInterval(-5400)
            ),
            createMockTrend(
                hashtag: "#HousingCrisis",
                title: nil,
                category: "Trending",
                postCount: 19800,
                createdAt: now.addingTimeInterval(-9000)
            )
        ]
    }

    private static func createMockTrend(
        hashtag: String?,
        title: String?,
        category: String,
        sourceName: String? = nil,
        sourceUrl: String? = nil,
        postCount: Int,
        createdAt: Date
    ) -> Trend {
        Trend(
            id: UUID(),
            hashtag: hashtag,
            title: title,
            category: category,
            sourceName: sourceName,
            sourceUrl: sourceUrl,
            imageUrl: nil,
            description: nil,
            postCount: postCount,
            isTrending: true,
            createdAt: createdAt,
            updatedAt: createdAt,
            expiresAt: createdAt.addingTimeInterval(86400)
        )
    }
}
