//
//  NewsCardView.swift
//  Chirp
//
//  Created by Juan Palacio on 10.12.2025.
//

import SwiftUI

/// News card view matching X's "Today's News" section
struct NewsCardView: View {
    let article: NewsAPIArticle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(article.title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Meta info: avatars + time + category + post count
            HStack(spacing: 6) {
                // Mock avatars (stacked)
                HStack(spacing: -8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color(UIColor.systemBackground), lineWidth: 1)
                            )
                    }
                }

                Text(article.relativeTimestamp())
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("·")
                    .foregroundColor(.secondary)

                Text(article.source.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

/// News card with image (for featured articles)
struct FeaturedNewsCardView: View {
    let article: NewsAPIArticle

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            if let imageUrl = article.urlToImage, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 180)
                            .clipped()
                    case .failure(_):
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 180)
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 180)
                            .overlay(ProgressView())
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 180)
                    }
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(article.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                // Description
                if let description = article.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Meta info
                HStack(spacing: 6) {
                    Text(article.source.name)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("·")
                        .foregroundColor(.secondary)

                    Text(article.relativeTimestamp())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: 0) {
        NewsCardView(article: NewsAPIArticle(
            source: .init(id: nil, name: "Reuters"),
            author: "Staff",
            title: "Workers Strike for Better Wages Across Multiple Industries",
            description: "Labor unions coordinate nationwide action demanding living wages.",
            url: "https://example.com",
            urlToImage: nil,
            publishedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)),
            content: nil
        ))
        Divider()
        NewsCardView(article: NewsAPIArticle(
            source: .init(id: nil, name: "The Intercept"),
            author: "Jane Doe",
            title: "Climate Report Shows Urgent Need for Policy Action Now",
            description: "New data reveals accelerating climate impacts.",
            url: "https://example.com",
            urlToImage: nil,
            publishedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-7200)),
            content: nil
        ))
        Divider()
    }
}
