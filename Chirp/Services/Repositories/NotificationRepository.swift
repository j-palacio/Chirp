//
//  NotificationRepository.swift
//  Chirp
//
//  Created by Juan Palacio on 11.12.2025.
//

import Foundation
import Supabase

/// Repository for notification-related database operations
final class NotificationRepository {
    private let supabase = SupabaseManager.shared.client

    // MARK: - Fetch Notifications

    /// Fetch all notifications for a user
    func fetchNotifications(userId: UUID, limit: Int = 50) async throws -> [AppNotification] {
        try await supabase
            .from("notifications")
            .select("*, actor:profiles!notifications_actor_id_fkey(*), posts(*)")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// Fetch unread notifications count
    func fetchUnreadCount(userId: UUID) async throws -> Int {
        let notifications: [AppNotification] = try await supabase
            .from("notifications")
            .select("id")
            .eq("user_id", value: userId)
            .eq("is_read", value: false)
            .execute()
            .value
        return notifications.count
    }

    /// Fetch notifications by type (for filtering)
    func fetchNotificationsByType(userId: UUID, type: NotificationType, limit: Int = 50) async throws -> [AppNotification] {
        try await supabase
            .from("notifications")
            .select("*, actor:profiles!notifications_actor_id_fkey(*), posts(*)")
            .eq("user_id", value: userId)
            .eq("type", value: type.rawValue)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// Fetch mention notifications only
    func fetchMentions(userId: UUID, limit: Int = 50) async throws -> [AppNotification] {
        try await fetchNotificationsByType(userId: userId, type: .mention, limit: limit)
    }

    // MARK: - Mark as Read

    /// Mark a single notification as read
    func markAsRead(notificationId: UUID) async throws {
        try await supabase
            .from("notifications")
            .update(["is_read": true])
            .eq("id", value: notificationId)
            .execute()
    }

    /// Mark all notifications as read for a user
    func markAllAsRead(userId: UUID) async throws {
        try await supabase
            .from("notifications")
            .update(["is_read": true])
            .eq("user_id", value: userId)
            .eq("is_read", value: false)
            .execute()
    }

    // MARK: - Create Notifications

    /// Create a notification (called when actions happen)
    func createNotification(userId: UUID, actorId: UUID?, type: NotificationType, postId: UUID? = nil) async throws {
        // Don't notify yourself
        if let actorId = actorId, actorId == userId {
            return
        }

        let insert = NotificationInsert(
            userId: userId,
            actorId: actorId,
            type: type.rawValue,
            postId: postId
        )

        try await supabase
            .from("notifications")
            .insert(insert)
            .execute()
    }

    // MARK: - Delete Notifications

    /// Delete a notification (e.g., when unliking a post)
    func deleteNotification(userId: UUID, actorId: UUID, type: NotificationType, postId: UUID? = nil) async throws {
        var query = supabase
            .from("notifications")
            .delete()
            .eq("user_id", value: userId)
            .eq("actor_id", value: actorId)
            .eq("type", value: type.rawValue)

        if let postId = postId {
            query = query.eq("post_id", value: postId)
        }

        try await query.execute()
    }
}
