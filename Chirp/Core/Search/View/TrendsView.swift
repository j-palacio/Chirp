//
//  TrendsView.swift
//  Chirp
//
//  Created by Juan Palacio on 10.12.2025.
//

import SwiftUI

/// Main trending/explore view that replaces MockTrends
struct TrendsView: View {
    @State private var selectedCategory: ExploreCategory = .forYou
    @State private var newsArticles: [NewsAPIArticle] = []
    @State private var trends: [Trend] = []
    @State private var isLoading = false
    @State private var error: String?

    private let newsService = NewsService.shared
    private let trendsRepository = TrendsRepository()
    private let twitterBlue = Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0))

    var body: some View {
        VStack(spacing: 0) {
            // Category tabs
            ExploreCategoryTabs(selectedCategory: $selectedCategory)
            Divider()

            // Content based on selected category
            ScrollView {
                LazyVStack(spacing: 0) {
                    if isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else if let error = error {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task {
                                    await loadContent()
                                }
                            }
                            .foregroundColor(twitterBlue)
                        }
                        .padding(.top, 40)
                        .padding(.horizontal)
                    } else {
                        contentForCategory
                    }
                }
            }
        }
        .task {
            await loadContent()
        }
        .onChange(of: selectedCategory) { _, _ in
            Task {
                await loadContent()
            }
        }
    }

    // MARK: - Content Views

    @ViewBuilder
    private var contentForCategory: some View {
        switch selectedCategory {
        case .forYou:
            forYouContent
        case .trending:
            trendingContent
        case .news:
            newsContent
        case .sports:
            sportsContent
        case .entertainment:
            entertainmentContent
        }
    }

    private var forYouContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Today's News section
            Text("Today's News")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            ForEach(newsArticles.prefix(3)) { article in
                NewsCardView(article: article)
                    .onTapGesture {
                        openArticle(article)
                    }
                Divider()
            }

            // Show more button
            if newsArticles.count > 3 {
                Button {
                    selectedCategory = .news
                } label: {
                    HStack {
                        Text("Show more")
                            .foregroundColor(twitterBlue)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                Divider()
            }

            // Trending section
            if !trends.isEmpty {
                Text("Trending")
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                ForEach(trends.prefix(5)) { trend in
                    TrendingTopicRow(trend: trend)
                        .onTapGesture {
                            searchTrend(trend)
                        }
                    Divider()
                }
            }
        }
    }

    private var trendingContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if trends.isEmpty {
                emptyStateView(message: "No trending topics yet")
            } else {
                ForEach(Array(trends.enumerated()), id: \.element.id) { index, trend in
                    NumberedTrendRow(rank: index + 1, trend: trend)
                        .onTapGesture {
                            searchTrend(trend)
                        }
                    Divider()
                }
            }
        }
    }

    private var newsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if newsArticles.isEmpty {
                emptyStateView(message: "No news available")
            } else {
                ForEach(newsArticles) { article in
                    NewsCardView(article: article)
                        .onTapGesture {
                            openArticle(article)
                        }
                    Divider()
                }
            }
        }
    }

    private var sportsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if newsArticles.isEmpty {
                emptyStateView(message: "No sports news available")
            } else {
                ForEach(newsArticles) { article in
                    NewsCardView(article: article)
                        .onTapGesture {
                            openArticle(article)
                        }
                    Divider()
                }
            }
        }
    }

    private var entertainmentContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if newsArticles.isEmpty {
                emptyStateView(message: "No entertainment news available")
            } else {
                ForEach(newsArticles) { article in
                    NewsCardView(article: article)
                        .onTapGesture {
                            openArticle(article)
                        }
                    Divider()
                }
            }
        }
    }

    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Data Loading

    private func loadContent() async {
        isLoading = true
        error = nil

        do {
            // Load news for selected category
            newsArticles = await newsService.fetchNews(category: selectedCategory)

            // Load trends from database (or use mock data)
            do {
                trends = try await trendsRepository.fetchTrends()
            } catch {
                // Use mock data if database fetch fails
                trends = TrendsRepository.getMockTrends()
            }

            isLoading = false
        }
    }

    // MARK: - Actions

    private func openArticle(_ article: NewsAPIArticle) {
        if let url = URL(string: article.url) {
            UIApplication.shared.open(url)
        }
    }

    private func searchTrend(_ trend: Trend) {
        // TODO: Navigate to search with trend query
        print("Searching for: \(trend.displayTitle)")
    }
}

#Preview {
    TrendsView()
}
