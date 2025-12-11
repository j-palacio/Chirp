import Foundation
import Supabase

/// Repository for post-related database operations
final class PostRepository {
    private let supabase = SupabaseManager.shared.client
    private let notificationRepository = NotificationRepository()

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

    func likePost(postId: UUID, userId: UUID, postAuthorId: UUID) async throws {
        let like = LikeInsert(userId: userId, postId: postId)
        try await supabase.from("likes").insert(like).execute()

        // Create notification for post author
        try? await notificationRepository.createNotification(
            userId: postAuthorId,
            actorId: userId,
            type: .like,
            postId: postId
        )
    }

    func unlikePost(postId: UUID, userId: UUID, postAuthorId: UUID) async throws {
        try await supabase
            .from("likes")
            .delete()
            .eq("post_id", value: postId)
            .eq("user_id", value: userId)
            .execute()

        // Remove notification
        try? await notificationRepository.deleteNotification(
            userId: postAuthorId,
            actorId: userId,
            type: .like,
            postId: postId
        )
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

    func repost(postId: UUID, userId: UUID, postAuthorId: UUID) async throws {
        let repost = RepostInsert(userId: userId, postId: postId)
        try await supabase.from("reposts").insert(repost).execute()

        // Create notification for post author
        try? await notificationRepository.createNotification(
            userId: postAuthorId,
            actorId: userId,
            type: .repost,
            postId: postId
        )
    }

    func unrepost(postId: UUID, userId: UUID, postAuthorId: UUID) async throws {
        try await supabase
            .from("reposts")
            .delete()
            .eq("post_id", value: postId)
            .eq("user_id", value: userId)
            .execute()

        // Remove notification
        try? await notificationRepository.deleteNotification(
            userId: postAuthorId,
            actorId: userId,
            type: .repost,
            postId: postId
        )
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

    func createComment(postId: UUID, authorId: UUID, content: String, postAuthorId: UUID) async throws -> Comment {
        let insert = CommentInsert(postId: postId, authorId: authorId, content: content)
        let comment: Comment = try await supabase
            .from("comments")
            .insert(insert)
            .select("*, profiles(*)")
            .single()
            .execute()
            .value

        // Create notification for post author
        try? await notificationRepository.createNotification(
            userId: postAuthorId,
            actorId: authorId,
            type: .comment,
            postId: postId
        )

        return comment
    }

    func deleteComment(commentId: UUID) async throws {
        try await supabase
            .from("comments")
            .delete()
            .eq("id", value: commentId)
            .execute()
    }

    // MARK: - Reporting

    func reportPost(postId: UUID, reporterId: UUID, reason: ReportReason, description: String?) async throws {
        let report = ReportInsert(
            reporterId: reporterId,
            reportedPostId: postId,
            reportedUserId: nil,
            reportedCommentId: nil,
            reason: reason.rawValue,
            description: description
        )
        try await supabase.from("content_reports").insert(report).execute()
    }

    func reportUser(userId: UUID, reporterId: UUID, reason: ReportReason, description: String?) async throws {
        let report = ReportInsert(
            reporterId: reporterId,
            reportedPostId: nil,
            reportedUserId: userId,
            reportedCommentId: nil,
            reason: reason.rawValue,
            description: description
        )
        try await supabase.from("content_reports").insert(report).execute()
    }

    func reportComment(commentId: UUID, reporterId: UUID, reason: ReportReason, description: String?) async throws {
        let report = ReportInsert(
            reporterId: reporterId,
            reportedPostId: nil,
            reportedUserId: nil,
            reportedCommentId: commentId,
            reason: reason.rawValue,
            description: description
        )
        try await supabase.from("content_reports").insert(report).execute()
    }

    // MARK: - Follow/Unfollow

    func followUser(followerId: UUID, followingId: UUID) async throws {
        let follow = FollowInsert(followerId: followerId, followingId: followingId)
        try await supabase.from("follows").insert(follow).execute()

        // Create notification for the user being followed
        try? await notificationRepository.createNotification(
            userId: followingId,
            actorId: followerId,
            type: .follow,
            postId: nil
        )
    }

    func unfollowUser(followerId: UUID, followingId: UUID) async throws {
        try await supabase
            .from("follows")
            .delete()
            .eq("follower_id", value: followerId)
            .eq("following_id", value: followingId)
            .execute()

        // Remove follow notification
        try? await notificationRepository.deleteNotification(
            userId: followingId,
            actorId: followerId,
            type: .follow,
            postId: nil
        )
    }

    func isFollowing(followerId: UUID, followingId: UUID) async throws -> Bool {
        let follows: [FollowRecord] = try await supabase
            .from("follows")
            .select("following_id")
            .eq("follower_id", value: followerId)
            .eq("following_id", value: followingId)
            .execute()
            .value
        return !follows.isEmpty
    }

    func fetchFollowers(userId: UUID) async throws -> [Profile] {
        let follows: [FollowWithProfile] = try await supabase
            .from("follows")
            .select("follower_id, profiles!follows_follower_id_fkey(*)")
            .eq("following_id", value: userId)
            .execute()
            .value
        return follows.compactMap { $0.profile }
    }

    func fetchFollowing(userId: UUID) async throws -> [Profile] {
        let follows: [FollowingWithProfile] = try await supabase
            .from("follows")
            .select("following_id, profiles!follows_following_id_fkey(*)")
            .eq("follower_id", value: userId)
            .execute()
            .value
        return follows.compactMap { $0.profile }
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

// MARK: - Report Types

enum ReportReason: String, CaseIterable {
    case harassment = "harassment"
    case hatespeech = "hate_speech"
    case identityThreat = "identity_threat"
    case spam = "spam"
    case misinformation = "misinformation"
    case other = "other"

    var displayName: String {
        switch self {
        case .harassment: return "Harassment"
        case .hatespeech: return "Hate Speech"
        case .identityThreat: return "Identity-based Threat"
        case .spam: return "Spam"
        case .misinformation: return "Misinformation"
        case .other: return "Other"
        }
    }

    var description: String {
        switch self {
        case .harassment: return "Targeted harassment or bullying"
        case .hatespeech: return "Hateful content based on protected characteristics"
        case .identityThreat: return "Threats based on race, religion, gender, etc."
        case .spam: return "Spam, scams, or misleading links"
        case .misinformation: return "False or misleading information"
        case .other: return "Other violation of community guidelines"
        }
    }
}

struct ReportInsert: Codable {
    let reporterId: UUID
    let reportedPostId: UUID?
    let reportedUserId: UUID?
    let reportedCommentId: UUID?
    let reason: String
    let description: String?

    enum CodingKeys: String, CodingKey {
        case reporterId = "reporter_id"
        case reportedPostId = "reported_post_id"
        case reportedUserId = "reported_user_id"
        case reportedCommentId = "reported_comment_id"
        case reason, description
    }
}

// MARK: - Follow Types

struct FollowInsert: Codable {
    let followerId: UUID
    let followingId: UUID

    enum CodingKeys: String, CodingKey {
        case followerId = "follower_id"
        case followingId = "following_id"
    }
}

struct FollowWithProfile: Codable {
    let followerId: UUID
    let profile: Profile?

    enum CodingKeys: String, CodingKey {
        case followerId = "follower_id"
        case profile = "profiles"
    }
}

struct FollowingWithProfile: Codable {
    let followingId: UUID
    let profile: Profile?

    enum CodingKeys: String, CodingKey {
        case followingId = "following_id"
        case profile = "profiles"
    }
}
