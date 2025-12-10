//
//  NewsService.swift
//  Chirp
//
//  Created by Juan Palacio on 10.12.2025.
//

import Foundation

// MARK: - RSS News Source

struct RSSNewsSource {
    let name: String
    let feedURL: String
    let category: String // "News", "Politics", "International", etc.
}

// MARK: - News Service (RSS-based, 100% FREE)

class NewsService {
    static let shared = NewsService()

    // Progressive news sources with RSS feeds
    private let sources: [RSSNewsSource] = [
        // Progressive/Left News
        RSSNewsSource(name: "Jacobin", feedURL: "https://jacobin.com/feed", category: "Politics"),
        RSSNewsSource(name: "The Intercept", feedURL: "https://theintercept.com/feed/?rss", category: "News"),
        RSSNewsSource(name: "Democracy Now!", feedURL: "https://www.democracynow.org/democracynow.rss", category: "News"),
        RSSNewsSource(name: "Common Dreams", feedURL: "https://www.commondreams.org/rss.xml", category: "Politics"),
        RSSNewsSource(name: "The Nation", feedURL: "https://www.thenation.com/feed/", category: "Politics"),
        RSSNewsSource(name: "In These Times", feedURL: "https://inthesetimes.com/feed", category: "Labor"),
        RSSNewsSource(name: "Current Affairs", feedURL: "https://www.currentaffairs.org/feed", category: "Politics"),

        // International
        RSSNewsSource(name: "Al Jazeera", feedURL: "https://www.aljazeera.com/xml/rss/all.xml", category: "International"),

        // Mainstream (for balance/reach)
        RSSNewsSource(name: "Reuters", feedURL: "https://www.reutersagency.com/feed/", category: "News"),
        RSSNewsSource(name: "AP News", feedURL: "https://rsshub.app/apnews/topics/apf-topnews", category: "News")
    ]

    // Cache
    private var cache: [String: (articles: [NewsAPIArticle], timestamp: Date)] = [:]
    private let cacheExpiration: TimeInterval = 15 * 60 // 15 minutes

    private init() {}

    // MARK: - Public Methods

    /// Fetch news for a category (uses RSS feeds)
    func fetchNews(category: ExploreCategory) async -> [NewsAPIArticle] {
        let cacheKey = "rss_\(category.rawValue)"

        // Check cache
        if let cached = cache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheExpiration {
            return cached.articles
        }

        // Filter sources by category
        let relevantSources: [RSSNewsSource]
        switch category {
        case .forYou, .trending:
            // Mix of all progressive sources
            relevantSources = sources.filter {
                ["Politics", "News", "Labor", "International"].contains($0.category)
            }
        case .news:
            relevantSources = sources.filter { $0.category == "News" || $0.category == "Politics" }
        case .sports:
            // No sports RSS sources currently - return empty
            return []
        case .entertainment:
            // No entertainment RSS sources currently - return empty
            return []
        }

        // Fetch from all relevant sources concurrently
        var allArticles: [NewsAPIArticle] = []

        await withTaskGroup(of: [NewsAPIArticle].self) { group in
            for source in relevantSources {
                group.addTask {
                    await self.fetchRSSFeed(source: source)
                }
            }

            for await articles in group {
                allArticles.append(contentsOf: articles)
            }
        }

        // Sort by date (newest first) and limit
        allArticles.sort { ($0.publishedDate ?? .distantPast) > ($1.publishedDate ?? .distantPast) }
        let limitedArticles = Array(allArticles.prefix(30))

        // Cache
        cache[cacheKey] = (limitedArticles, Date())

        return limitedArticles
    }

    /// Fetch progressive news specifically
    func fetchProgressiveNews() async -> [NewsAPIArticle] {
        return await fetchNews(category: .forYou)
    }

    /// Clear cache
    func clearCache() {
        cache.removeAll()
    }

    // MARK: - RSS Parsing

    private func fetchRSSFeed(source: RSSNewsSource) async -> [NewsAPIArticle] {
        guard let url = URL(string: source.feedURL) else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return parseRSS(data: data, source: source)
        } catch {
            print("Error fetching RSS from \(source.name): \(error.localizedDescription)")
            return []
        }
    }

    private func parseRSS(data: Data, source: RSSNewsSource) -> [NewsAPIArticle] {
        let parser = RSSParser(source: source)
        return parser.parse(data: data)
    }
}

// MARK: - RSS Parser

private class RSSParser: NSObject, XMLParserDelegate {
    private let source: RSSNewsSource
    private var articles: [NewsAPIArticle] = []

    private var currentElement = ""
    private var currentTitle = ""
    private var currentDescription = ""
    private var currentLink = ""
    private var currentPubDate = ""
    private var currentImageURL: String?
    private var isInItem = false

    init(source: RSSNewsSource) {
        self.source = source
    }

    func parse(data: Data) -> [NewsAPIArticle] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return articles
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName

        if elementName == "item" || elementName == "entry" {
            isInItem = true
            currentTitle = ""
            currentDescription = ""
            currentLink = ""
            currentPubDate = ""
            currentImageURL = nil
        }

        // Handle media:content or enclosure for images
        if isInItem {
            if elementName == "media:content" || elementName == "media:thumbnail" {
                currentImageURL = attributeDict["url"]
            } else if elementName == "enclosure" {
                if let type = attributeDict["type"], type.starts(with: "image") {
                    currentImageURL = attributeDict["url"]
                }
            }
            // Atom link
            if elementName == "link" {
                if let href = attributeDict["href"] {
                    currentLink = href
                }
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard isInItem else { return }

        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        switch currentElement {
        case "title":
            currentTitle += trimmed
        case "description", "summary", "content:encoded":
            currentDescription += trimmed
        case "link":
            if currentLink.isEmpty {
                currentLink += trimmed
            }
        case "pubDate", "published", "dc:date", "updated":
            currentPubDate += trimmed
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" || elementName == "entry" {
            // Clean up HTML from description
            let cleanDescription = currentDescription
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // Parse date
            let publishedAt = parseDate(currentPubDate)

            let article = NewsAPIArticle(
                source: NewsAPIArticle.NewsSource(id: source.name.lowercased().replacingOccurrences(of: " ", with: "-"), name: source.name),
                author: nil,
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                description: cleanDescription.isEmpty ? nil : String(cleanDescription.prefix(300)),
                url: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                urlToImage: currentImageURL,
                publishedAt: publishedAt,
                content: nil
            )

            // Only add if we have title and link
            if !article.title.isEmpty && !article.url.isEmpty {
                articles.append(article)
            }

            isInItem = false
        }

        currentElement = ""
    }

    private func parseDate(_ dateString: String) -> String {
        // Try various date formats
        let formatters: [DateFormatter] = {
            let formats = [
                "EEE, dd MMM yyyy HH:mm:ss Z",      // RFC 822
                "EEE, dd MMM yyyy HH:mm:ss zzz",   // RFC 822 variant
                "yyyy-MM-dd'T'HH:mm:ssZ",          // ISO 8601
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",      // ISO 8601 with milliseconds
                "yyyy-MM-dd'T'HH:mm:ssXXXXX",      // ISO 8601 with timezone
                "yyyy-MM-dd HH:mm:ss",             // Simple
                "dd MMM yyyy HH:mm:ss Z"           // Another common format
            ]
            return formats.map { format -> DateFormatter in
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = format
                return formatter
            }
        }()

        // Try ISO8601DateFormatter first
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: dateString) {
            return ISO8601DateFormatter().string(from: date)
        }
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: dateString) {
            return ISO8601DateFormatter().string(from: date)
        }

        // Try other formatters
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return ISO8601DateFormatter().string(from: date)
            }
        }

        // Fallback to current date
        return ISO8601DateFormatter().string(from: Date())
    }
}

// MARK: - Note on Curated Voices

/*
 The following shows/personalities should be added as CURATED VOICES
 (journalist category) in the Supabase database, NOT as RSS sources
 since they're YouTube/podcast based:

 - Majority Report (Sam Seder) - @majorityrpt
 - Breaking Points (Krystal Ball & Saagar Enjeti) - @breakingpoints
 - Hasan Piker - @hasanabi (already added!)

 Add via Supabase dashboard or run SQL:

 -- After creating their user accounts:
 UPDATE profiles
 SET is_curated_voice = true, voice_category = 'journalist'
 WHERE username IN ('majorityrpt', 'breakingpoints');

 INSERT INTO curated_sources (user_id, category, institution)
 SELECT id, 'journalist', 'Independent Media'
 FROM profiles WHERE username IN ('majorityrpt', 'breakingpoints');
*/
