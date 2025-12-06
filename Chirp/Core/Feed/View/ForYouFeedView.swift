//
//  ForYouFeedView.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202425.11.2023.
//

import SwiftUI

struct ForYouFeedView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = FeedViewModel()

    var body: some View {
        Group {
            if viewModel.isLoadingForYou && viewModel.forYouPosts.isEmpty {
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading posts...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
            } else if viewModel.forYouPosts.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "text.bubble")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No posts yet")
                        .font(.headline)
                    Text("Be the first to share something!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                FeedScrollView(
                    posts: viewModel.forYouPosts,
                    isLoading: viewModel.isLoadingForYou,
                    hasMore: viewModel.hasMoreForYou,
                    onLoadMore: {
                        Task {
                            await viewModel.loadMoreForYou()
                        }
                    },
                    onRefresh: {
                        Task {
                            await viewModel.refreshForYouFeed()
                        }
                    }
                )
            }
        }
        .task {
            if viewModel.forYouPosts.isEmpty {
                await viewModel.refreshForYouFeed()
            }
        }
    }
}

// MARK: - Feed Scroll View

struct FeedScrollView: View {
    let posts: [Post]
    let isLoading: Bool
    let hasMore: Bool
    let onLoadMore: () -> Void
    let onRefresh: () -> Void

    @State private var scrollViewOffset: CGFloat = 0
    @State private var startOffset: CGFloat = 0

    var body: some View {
        ScrollViewReader { proxyReader in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(posts) { post in
                        PostRowView(post: post)
                        Divider()
                            .onAppear {
                                // Load more when reaching near the end
                                if post.id == posts.suffix(5).first?.id && hasMore && !isLoading {
                                    onLoadMore()
                                }
                            }
                    }

                    if isLoading && !posts.isEmpty {
                        ProgressView()
                            .padding()
                    }
                }
                .id("scrollToTop")
                .overlay(
                    GeometryReader { proxy -> Color in
                        DispatchQueue.main.async {
                            if startOffset == 0 {
                                self.startOffset = proxy.frame(in: .global).minY
                            }
                            let offset = proxy.frame(in: .global).minY
                            self.scrollViewOffset = offset - startOffset
                        }
                        return Color.clear
                    }
                )
            }
            .padding(.top, 50)
            .refreshable {
                onRefresh()
            }
            .overlay(
                scrollViewOffset <= -150 ?
                Button {
                    withAnimation(.spring()) {
                        proxyReader.scrollTo("scrollToTop", anchor: .top)
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.up")
                            .foregroundStyle(.white)
                            .imageScale(.large)
                    }
                    .frame(width: 42, height: 42)
                    .background(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0)))
                    .clipShape(Circle())
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 60)
                : nil
            )
            .animation(.bouncy, value: scrollViewOffset <= -150)
        }
    }
}

// MARK: - Post Row View (works with new Post struct)

struct PostRowView: View {
    let post: Post

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // User avatar
            AsyncImage(url: URL(string: post.author?.avatarUrl ?? "https://i.pravatar.cc/48")) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .cornerRadius(99)
                } else if phase.error != nil {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 48, height: 48)
                } else {
                    ProgressView()
                        .frame(width: 48, height: 48)
                }
            }

            // Post information
            VStack(alignment: .leading, spacing: 5) {
                // Post author information
                HStack {
                    // Author name
                    Text(post.author?.fullName ?? "Unknown")
                        .fontWeight(.bold)

                    HStack(spacing: 2) {
                        // Username
                        Text("@\(post.author?.username ?? "unknown")")

                        // Verified badge
                        if post.author?.isVerified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0)))
                                .font(.caption)
                        }

                        // Curated voice badge
                        if post.author?.isCuratedVoice == true {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }

                        Text("•")

                        // Timestamp
                        Text(post.relativeTimestamp())
                    }
                    .foregroundStyle(.secondary)
                    .font(.footnote)

                    Spacer()

                    Button {} label: {
                        Image(systemName: "ellipsis")
                            .tint(.secondary)
                    }
                }

                // Post content
                Text(post.content)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Post image (if any)
                if let imageUrl = post.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxHeight: 200)
                                .cornerRadius(12)
                                .clipped()
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Post actions
                HStack(spacing: 20) {
                    // Comments
                    Button {} label: {
                        Label(formatCount(post.commentCount), systemImage: "bubble")
                    }

                    // Reposts
                    Button {} label: {
                        Label(formatCount(post.repostCount), systemImage: "arrow.2.squarepath")
                    }

                    // Likes
                    Button {} label: {
                        Label(formatCount(post.likeCount), systemImage: "heart")
                    }

                    // Views
                    Button {} label: {
                        Label(formatCount(post.viewCount), systemImage: "chart.bar.fill")
                    }
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.callout)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}

#Preview {
    ForYouFeedView()
        .environmentObject(AuthManager())
}
