import Foundation
import Supabase

/// Repository for post-related database operations
final class PostRepository {
    private let supabase = SupabaseManager.shared.client

    // MARK: - Fetch Posts

    /// Fetch feed posts with author data
    func fetchFeedPosts(limit: Int = 20, offset: Int = 0) async throws -> [Post] {
        try await supabase
            .from("posts")
            .select("*, profiles(*)")
            .eq("moderation_status", value: "approved")
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
    }

    /// Fetch curated feed (posts from curated voices - "For You" tab)
    func fetchCuratedFeed(limit: Int = 20, offset: Int = 0) async throws -> [Post] {
        try await supabase
            .from("posts")
            .select("*, profiles!inner(*)")
            .eq("moderation_status", value: "approved")
            .eq("profiles.is_curated_voice", value: true)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
    }

    /// Fetch following feed (posts from users you follow)
    func fetchFollowingFeed(userId: UUID, limit: Int = 20, offset: Int = 0) async throws -> [Post] {
        // First get following IDs
        let follows: [FollowRecord] = try await supabase
            .from("follows")
            .select("following_id")
            .eq("follower_id", value: userId)
            .execute()
            .value

        let followingIds = follows.map { $0.followingId }

        guard !followingIds.isEmpty else { return [] }

        return try await supabase
            .from("posts")
            .select("*, profiles(*)")
            .eq("moderation_status", value: "approved")
            .in("author_id", values: followingIds)
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
    }

    /// Fetch user's posts
    func fetchUserPosts(userId: UUID, limit: Int = 20, offset: Int = 0) async throws -> [Post] {
        try await supabase
            .from("posts")
            .select("*, profiles(*)")
            .eq("author_id", value: userId)
            .eq("moderation_status", value: "approved")
            .order("created_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
    }

    /// Fetch a single post by ID
    func fetchPost(postId: UUID) async throws -> Post {
        try await supabase
            .from("posts")
            .select("*, profiles(*)")
            .eq("id", value: postId)
            .single()
            .execute()
            .value
    }

    // MARK: - Create Post

    func createPost(authorId: UUID, content: String, imageUrl: String? = nil) async throws -> Post {
        let insert = PostInsert(authorId: authorId, content: content, imageUrl: imageUrl)
        return try await supabase
            .from("posts")
            .insert(insert)
            .select("*, profiles(*)")
            .single()
            .execute()
            .value
    }

    // MARK: - Delete Post

    func deletePost(postId: UUID) async throws {
        try await supabase
            .from("posts")
            .delete()
            .eq("id", value: postId)
            .execute()
    }

    // MARK: - Likes

    func likePost(postId: UUID, userId: UUID) async throws {
        let like = LikeInsert(userId: userId, postId: postId)
        try await supabase.from("likes").insert(like).execute()
    }

    func unlikePost(postId: UUID, userId: UUID) async throws {
        try await supabase
            .from("likes")
            .delete()
            .eq("post_id", value: postId)
            .eq("user_id", value: userId)
            .execute()
    }

    func hasUserLikedPost(postId: UUID, userId: UUID) async throws -> Bool {
        let likes: [LikeRecord] = try await supabase
            .from("likes")
            .select("id")
            .eq("post_id", value: postId)
            .eq("user_id", value: userId)
            .execute()
            .value
        return !likes.isEmpty
    }

    // MARK: - Reposts

    func repost(postId: UUID, userId: UUID) async throws {
        let repost = RepostInsert(userId: userId, postId: postId)
        try await supabase.from("reposts").insert(repost).execute()
    }

    func unrepost(postId: UUID, userId: UUID) async throws {
        try await supabase
            .from("reposts")
            .delete()
            .eq("post_id", value: postId)
            .eq("user_id", value: userId)
            .execute()
    }
}

// MARK: - Helper Structs

struct FollowRecord: Codable {
    let followingId: UUID

    enum CodingKeys: String, CodingKey {
        case followingId = "following_id"
    }
}

struct LikeInsert: Codable {
    let userId: UUID
    let postId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case postId = "post_id"
    }
}

struct LikeRecord: Codable {
    let id: UUID
}

struct RepostInsert: Codable {
    let userId: UUID
    let postId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case postId = "post_id"
    }
}
