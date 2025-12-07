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

    /// Fetch curated feed using the algorithm (scores by priority, engagement, recency)
    func fetchCuratedFeed(limit: Int = 20, offset: Int = 0) async throws -> [Post] {
        // First try the algorithmic feed
        let scoredPosts: [ScoredPost] = try await supabase
            .rpc("get_curated_feed", params: ["p_limit": limit, "p_offset": offset])
            .execute()
            .value

        // Now fetch with profiles for each post
        let postIds = scoredPosts.map { $0.id }
        guard !postIds.isEmpty else { return [] }

        let posts: [Post] = try await supabase
            .from("posts")
            .select("*, profiles(*)")
            .in("id", values: postIds)
            .execute()
            .value

        // Sort by the algorithm's score order
        let postDict = Dictionary(uniqueKeysWithValues: posts.map { ($0.id, $0) })
        return postIds.compactMap { postDict[$0] }
    }

    /// Fetch curated feed (simple version - posts from curated voices only)
    func fetchCuratedVoicesFeed(limit: Int = 20, offset: Int = 0) async throws -> [Post] {
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

    func hasUserReposted(postId: UUID, userId: UUID) async throws -> Bool {
        let reposts: [RepostRecord] = try await supabase
            .from("reposts")
            .select("id")
            .eq("post_id", value: postId)
            .eq("user_id", value: userId)
            .execute()
            .value
        return !reposts.isEmpty
    }

    // MARK: - Views/Impressions

    func recordView(postId: UUID, userId: UUID) async throws {
        try await supabase
            .rpc("record_post_view", params: ["p_post_id": postId, "p_user_id": userId])
            .execute()
    }

    // MARK: - Comments

    func fetchComments(postId: UUID, limit: Int = 50, offset: Int = 0) async throws -> [Comment] {
        try await supabase
            .from("comments")
            .select("*, profiles(*)")
            .eq("post_id", value: postId)
            .eq("moderation_status", value: "approved")
            .order("created_at", ascending: true)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
    }

    func createComment(postId: UUID, authorId: UUID, content: String) async throws -> Comment {
        let insert = CommentInsert(postId: postId, authorId: authorId, content: content)
        return try await supabase
            .from("comments")
            .insert(insert)
            .select("*, profiles(*)")
            .single()
            .execute()
            .value
    }

    func deleteComment(commentId: UUID) async throws {
        try await supabase
            .from("comments")
            .delete()
            .eq("id", value: commentId)
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

struct RepostRecord: Codable {
    let id: UUID
}

struct CommentInsert: Codable {
    let postId: UUID
    let authorId: UUID
    let content: String

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case authorId = "author_id"
        case content
    }
}

struct Comment: Codable, Identifiable {
    let id: UUID
    let postId: UUID
    let authorId: UUID
    let content: String
    let moderationStatus: String
    let createdAt: Date
    var author: Profile?

    enum CodingKeys: String, CodingKey {
        case id, content
        case postId = "post_id"
        case authorId = "author_id"
        case moderationStatus = "moderation_status"
        case createdAt = "created_at"
        case author = "profiles"
    }

    func relativeTimestamp() -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: createdAt, to: Date())

        if let years = components.year, years > 0 {
            return "\(years)y"
        } else if let months = components.month, months > 0 {
            return "\(months)mo"
        } else if let days = components.day, days > 0 {
            return "\(days)d"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m"
        } else {
            return "now"
        }
    }
}

struct ScoredPost: Codable {
    let id: UUID
    let authorId: UUID
    let content: String
    let imageUrl: String?
    let likeCount: Int
    let commentCount: Int
    let repostCount: Int
    let viewCount: Int
    let isCurated: Bool
    let moderationStatus: String
    let createdAt: Date
    let updatedAt: Date
    let feedScore: Double

    enum CodingKeys: String, CodingKey {
        case id, content
        case authorId = "author_id"
        case imageUrl = "image_url"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case repostCount = "repost_count"
        case viewCount = "view_count"
        case isCurated = "is_curated"
        case moderationStatus = "moderation_status"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case feedScore = "feed_score"
    }
}
