//
//  UserModel.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202426.11.2023.
//

import Foundation

// MARK: - Profile (from Supabase)

struct Profile: Codable, Identifiable {
    let id: UUID
    let username: String
    let fullName: String
    let bio: String?
    let avatarUrl: String?
    let bannerUrl: String?
    let isVerified: Bool
    let isCuratedVoice: Bool
    let voiceCategory: String?
    let followerCount: Int
    let followingCount: Int
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, username, bio
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case bannerUrl = "banner_url"
        case isVerified = "is_verified"
        case isCuratedVoice = "is_curated_voice"
        case voiceCategory = "voice_category"
        case followerCount = "follower_count"
        case followingCount = "following_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Profile Insert (for creating new profiles)

struct ProfileInsert: Codable {
    let id: UUID
    let username: String
    let fullName: String

    enum CodingKeys: String, CodingKey {
        case id, username
        case fullName = "full_name"
    }
}

// MARK: - Profile Update (for updating profiles)

struct ProfileUpdate: Codable {
    var fullName: String?
    var bio: String?
    var avatarUrl: String?
    var bannerUrl: String?

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case bio
        case avatarUrl = "avatar_url"
        case bannerUrl = "banner_url"
    }
}

// MARK: - Legacy UserModel (for backward compatibility)

final class UserModel {
    let userId: String
    let username: String
    let fullName: String

    init(userId: String, username: String, fullName: String) {
        self.userId = userId
        self.username = username
        self.fullName = fullName
    }

    /// Create from Profile
    convenience init(from profile: Profile) {
        self.init(
            userId: profile.id.uuidString,
            username: profile.username,
            fullName: profile.fullName
        )
    }
}
