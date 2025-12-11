//
//  FeedViewModel.swift
//  Chirp
//
//  Created by Juan Palacio on 05.12.2025.
//

import Foundation
import SwiftUI

/// ViewModel for managing feed state and data
@MainActor
final class FeedViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var forYouPosts: [Post] = []
    @Published var followingPosts: [Post] = []
    @Published var isLoadingForYou = false
    @Published var isLoadingFollowing = false
    @Published var errorMessage: String?
    @Published var hasMoreForYou = true
    @Published var hasMoreFollowing = true

    // MARK: - Private Properties

    private let postRepository = PostRepository()
    private var forYouOffset = 0
    private var followingOffset = 0
    private let pageSize = 20

    // MARK: - For You Feed (Curated)

    /// Fetch curated feed (posts from curated voices)
    func fetchForYouFeed(refresh: Bool = false) async {
        guard !isLoadingForYou else { return }

        if refresh {
            forYouOffset = 0
            hasMoreForYou = true
        }

        guard hasMoreForYou else { return }

        isLoadingForYou = true
        errorMessage = nil

        do {
            let posts = try await postRepository.fetchCuratedFeed(limit: pageSize, offset: forYouOffset)

            if refresh {
                forYouPosts = posts
            } else {
                forYouPosts.append(contentsOf: posts)
            }

            hasMoreForYou = posts.count == pageSize
            forYouOffset += posts.count
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingForYou = false
    }

    /// Fetch general feed (all approved posts) - fallback if no curated content
    func fetchGeneralFeed(refresh: Bool = false) async {
        guard !isLoadingForYou else { return }

        if refresh {
            forYouOffset = 0
            hasMoreForYou = true
        }

        guard hasMoreForYou else { return }

        isLoadingForYou = true
        errorMessage = nil

        do {
            let posts = try await postRepository.fetchFeedPosts(limit: pageSize, offset: forYouOffset)

            if refresh {
                forYouPosts = posts
            } else {
                forYouPosts.append(contentsOf: posts)
            }

            hasMoreForYou = posts.count == pageSize
            forYouOffset += posts.count
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingForYou = false
    }

    // MARK: - Following Feed

    /// Fetch posts from users the current user follows
    func fetchFollowingFeed(userId: UUID, refresh: Bool = false) async {
        guard !isLoadingFollowing else { return }

        if refresh {
            followingOffset = 0
            hasMoreFollowing = true
        }

        guard hasMoreFollowing else { return }

        isLoadingFollowing = true
        errorMessage = nil

        do {
            let posts = try await postRepository.fetchFollowingFeed(userId: userId, limit: pageSize, offset: followingOffset)

            if refresh {
                followingPosts = posts
            } else {
                followingPosts.append(contentsOf: posts)
            }

            hasMoreFollowing = posts.count == pageSize
            followingOffset += posts.count
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingFollowing = false
    }

    // MARK: - Post Actions

    /// Like a post
    func likePost(_ post: Post, userId: UUID) async {
        do {
            try await postRepository.likePost(postId: post.id, userId: userId, postAuthorId: post.authorId)
            // Update local state
            if let index = forYouPosts.firstIndex(where: { $0.id == post.id }) {
                var updatedPost = forYouPosts[index]
                // Note: likeCount is let, so we need to refetch or track locally
            }
            if let index = followingPosts.firstIndex(where: { $0.id == post.id }) {
                // Update following posts too
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Unlike a post
    func unlikePost(_ post: Post, userId: UUID) async {
        do {
            try await postRepository.unlikePost(postId: post.id, userId: userId, postAuthorId: post.authorId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Repost a post
    func repost(_ post: Post, userId: UUID) async {
        do {
            try await postRepository.repost(postId: post.id, userId: userId, postAuthorId: post.authorId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Remove repost
    func unrepost(_ post: Post, userId: UUID) async {
        do {
            try await postRepository.unrepost(postId: post.id, userId: userId, postAuthorId: post.authorId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Create a new post
    func createPost(authorId: UUID, content: String, imageUrl: String? = nil) async -> Post? {
        do {
            let post = try await postRepository.createPost(authorId: authorId, content: content, imageUrl: imageUrl)
            // Add to the beginning of the feed
            forYouPosts.insert(post, at: 0)
            followingPosts.insert(post, at: 0)
            return post
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    /// Delete a post
    func deletePost(_ post: Post) async {
        do {
            try await postRepository.deletePost(postId: post.id)
            // Remove from local state
            forYouPosts.removeAll { $0.id == post.id }
            followingPosts.removeAll { $0.id == post.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Refresh

    /// Pull to refresh for For You tab
    func refreshForYouFeed() async {
        await fetchForYouFeed(refresh: true)

        // If curated feed is empty, fall back to general feed
        if forYouPosts.isEmpty {
            await fetchGeneralFeed(refresh: true)
        }
    }

    /// Pull to refresh for Following tab
    func refreshFollowingFeed(userId: UUID) async {
        await fetchFollowingFeed(userId: userId, refresh: true)
    }

    // MARK: - Pagination

    /// Load more for For You tab
    func loadMoreForYou() async {
        await fetchForYouFeed()

        // If curated feed has no more, try general feed
        if !hasMoreForYou && forYouPosts.isEmpty {
            await fetchGeneralFeed()
        }
    }

    /// Load more for Following tab
    func loadMoreFollowing(userId: UUID) async {
        await fetchFollowingFeed(userId: userId)
    }
}

// MARK: - Post Extension for Legacy Compatibility

extension Post {
    /// Convert to legacy PostModel for existing UI components
    func toPostModel() -> PostModel {
        PostModel(from: self)
    }
}
