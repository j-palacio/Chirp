//
//  NotificationModel.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.2024
//

import Foundation
import SwiftUI

// MARK: - AppNotification (from Supabase)

struct AppNotification: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let actorId: UUID?
    let type: NotificationType
    let postId: UUID?
    let isRead: Bool
    let createdAt: Date

    // Joined data
    var actor: Profile?
    var post: Post?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case actorId = "actor_id"
        case type
        case postId = "post_id"
        case isRead = "is_read"
        case createdAt = "created_at"
        case actor = "actor"
        case post = "posts"
    }

    /// Action text (e.g., "followed you", "liked your post")
    var actionText: String {
        switch type {
        case .like:
            return "liked your post"
        case .comment:
            return "commented on your post"
        case .follow:
            return "followed you"
        case .repost:
            return "reposted your post"
        case .mention:
            return "mentioned you"
        case .moderation:
            return "Post flagged for review"
        }
    }

    /// Icon name for notification type
    var iconName: String {
        switch type {
        case .like:
            return "heart.fill"
        case .comment:
            return "bubble.left.fill"
        case .follow:
            return "person.fill"
        case .repost:
            return "arrow.2.squarepath"
        case .mention:
            return "at"
        case .moderation:
            return "exclamationmark.triangle.fill"
        }
    }

    /// Icon color for notification type
    var iconColor: Color {
        switch type {
        case .like:
            return .pink
        case .comment:
            return Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0))
        case .follow:
            return Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0))
        case .repost:
            return .green
        case .mention:
            return Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0))
        case .moderation:
            return .orange
        }
    }

    /// Relative timestamp
    func relativeTimestamp() -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .minute], from: createdAt, to: Date())

        if let days = components.day, days > 0 {
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

// MARK: - Notification Type

enum NotificationType: String, Codable, CaseIterable {
    case like
    case comment
    case follow
    case repost
    case mention
    case moderation
}

// MARK: - Notification Insert

struct NotificationInsert: Codable {
    let userId: UUID
    let actorId: UUID?
    let type: String
    let postId: UUID?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case actorId = "actor_id"
        case type
        case postId = "post_id"
    }
}

// MARK: - Legacy NotificationModel (keeping for backward compatibility)

final class NotificationModel {
    let title: String
    let description: String

    init(title: String, description: String) {
        self.title = title
        self.description = description
    }
}
