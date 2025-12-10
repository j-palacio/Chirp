//
//  TrendingTopicRow.swift
//  Chirp
//
//  Created by Juan Palacio on 10.12.2025.
//

import SwiftUI

/// Simple trending topic row matching X's trending section
struct TrendingTopicRow: View {
    let trend: Trend

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Topic/Hashtag
                Text(trend.displayTitle)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // Post count
                Text(trend.formattedPostCount)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Category label
                if let category = trend.category {
                    Text(trend.isTrending ? "\(category) · Trending" : category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if trend.isTrending {
                    Text("Trending")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // More button
            Button {
                // More options action
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
                    .padding(8)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

/// Trending topic row from hashtag string (for quick display)
struct HashtagTrendRow: View {
    let hashtag: String
    let postCount: Int
    let category: String?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Hashtag
                Text(hashtag)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // Post count
                Text(formatPostCount(postCount))
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Category
                if let category = category {
                    Text("\(category) · Trending")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Trending")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button {
                // More options
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
                    .padding(8)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }

    private func formatPostCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM posts", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK posts", Double(count) / 1_000)
        }
        return "\(count) posts"
    }
}

/// Numbered trending topic (for ranked lists)
struct NumberedTrendRow: View {
    let rank: Int
    let trend: Trend

    var body: some View {
        HStack(spacing: 12) {
            // Rank number
            Text("\(rank)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                // Category
                if let category = trend.category {
                    Text(category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Topic
                Text(trend.displayTitle)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // Post count
                Text(trend.formattedPostCount)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                // More options
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
                    .padding(8)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: 0) {
        TrendingTopicRow(trend: Trend(
            id: UUID(),
            hashtag: "#LaborRights",
            title: nil,
            category: "Politics",
            sourceName: nil,
            sourceUrl: nil,
            imageUrl: nil,
            description: nil,
            postCount: 45200,
            isTrending: true,
            createdAt: Date(),
            updatedAt: Date(),
            expiresAt: nil
        ))
        Divider()

        HashtagTrendRow(hashtag: "#ClimateAction", postCount: 32100, category: "Environment")
        Divider()

        NumberedTrendRow(rank: 1, trend: Trend(
            id: UUID(),
            hashtag: "#MedicareForAll",
            title: nil,
            category: "Healthcare",
            sourceName: nil,
            sourceUrl: nil,
            imageUrl: nil,
            description: nil,
            postCount: 28500,
            isTrending: true,
            createdAt: Date(),
            updatedAt: Date(),
            expiresAt: nil
        ))
        Divider()
    }
}
