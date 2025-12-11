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
            .padding(.top, 5)
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
    @EnvironmentObject var authManager: AuthManager

    @State private var isLiked = false
    @State private var isReposted = false
    @State private var likeCount: Int
    @State private var repostCount: Int
    @State private var viewCount: Int
    @State private var commentCount: Int
    @State private var isProcessing = false
    @State private var showPostDetail = false
    @State private var hasRecordedView = false
    @State private var showReportSheet = false
    @State private var showProfile = false

    private let postRepository = PostRepository()
    private let twitterBlue = Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0))

    init(post: Post) {
        self.post = post
        _likeCount = State(initialValue: post.likeCount)
        _repostCount = State(initialValue: post.repostCount)
        _viewCount = State(initialValue: post.viewCount)
        _commentCount = State(initialValue: post.commentCount)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // User avatar - tappable to view profile
            Button {
                showProfile = true
            } label: {
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
            }

            // Post information
            VStack(alignment: .leading, spacing: 5) {
                // Post author information
                HStack {
                    // Author name - tappable to view profile
                    Button {
                        showProfile = true
                    } label: {
                        Text(post.author?.fullName ?? "Unknown")
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }

                    HStack(spacing: 2) {
                        // Username
                        Text("@\(post.author?.username ?? "unknown")")

                        // Verified badge
                        if post.author?.isVerified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(twitterBlue)
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

                    Menu {
                        Button(role: .destructive) {
                            showReportSheet = true
                        } label: {
                            Label("Report Post", systemImage: "flag")
                        }
                    } label: {
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
                    Button {
                        showPostDetail = true
                    } label: {
                        Label(formatCount(commentCount), systemImage: "bubble")
                    }
                    .foregroundColor(.secondary)

                    // Reposts
                    Button {
                        toggleRepost()
                    } label: {
                        Label(formatCount(repostCount), systemImage: "arrow.2.squarepath")
                    }
                    .foregroundColor(isReposted ? .green : .secondary)

                    // Likes
                    Button {
                        toggleLike()
                    } label: {
                        Label(formatCount(likeCount), systemImage: isLiked ? "heart.fill" : "heart")
                    }
                    .foregroundColor(isLiked ? .red : .secondary)

                    // Views
                    Label(formatCount(viewCount), systemImage: "chart.bar.fill")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.callout)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            showPostDetail = true
        }
        .task {
            await checkUserInteractions()
            await recordView()
        }
        .sheet(isPresented: $showPostDetail) {
            PostDetailView(post: post, commentCount: $commentCount)
        }
        .sheet(isPresented: $showReportSheet) {
            if let userId = authManager.currentUser?.id {
                ReportSheetView(postId: post.id, userId: nil, commentId: nil, reporterId: userId)
            }
        }
        .sheet(isPresented: $showProfile) {
            if let author = post.author {
                ProfileView(profileToShow: author)
                    .environmentObject(authManager)
            }
        }
    }

    private func recordView() async {
        guard !hasRecordedView, let userId = authManager.currentUser?.id else { return }
        hasRecordedView = true

        do {
            // Record view - the database function handles deduplication
            // Don't do optimistic update since the DB function only increments once per user
            try await postRepository.recordView(postId: post.id, userId: userId)
        } catch {
            print("Error recording view: \(error)")
        }
    }

    private func checkUserInteractions() async {
        guard let userId = authManager.currentUser?.id else { return }

        do {
            isLiked = try await postRepository.hasUserLikedPost(postId: post.id, userId: userId)
            isReposted = try await postRepository.hasUserReposted(postId: post.id, userId: userId)
        } catch {
            print("Error checking interactions: \(error)")
        }
    }

    private func toggleLike() {
        guard !isProcessing, let userId = authManager.currentUser?.id else { return }
        isProcessing = true

        // Optimistic update
        isLiked.toggle()
        likeCount += isLiked ? 1 : -1

        Task {
            do {
                if isLiked {
                    try await postRepository.likePost(postId: post.id, userId: userId, postAuthorId: post.authorId)
                } else {
                    try await postRepository.unlikePost(postId: post.id, userId: userId, postAuthorId: post.authorId)
                }
            } catch {
                // Revert on error
                isLiked.toggle()
                likeCount += isLiked ? 1 : -1
                print("Error toggling like: \(error)")
            }
            isProcessing = false
        }
    }

    private func toggleRepost() {
        guard !isProcessing, let userId = authManager.currentUser?.id else { return }
        isProcessing = true

        // Optimistic update
        isReposted.toggle()
        repostCount += isReposted ? 1 : -1

        Task {
            do {
                if isReposted {
                    try await postRepository.repost(postId: post.id, userId: userId, postAuthorId: post.authorId)
                } else {
                    try await postRepository.unrepost(postId: post.id, userId: userId, postAuthorId: post.authorId)
                }
            } catch {
                // Revert on error
                isReposted.toggle()
                repostCount += isReposted ? 1 : -1
                print("Error toggling repost: \(error)")
            }
            isProcessing = false
        }
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
