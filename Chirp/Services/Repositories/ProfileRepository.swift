//
//  ProfileRepository.swift
//  Chirp
//
//  Created by Juan Palacio on 08.12.2025.
//

import Foundation
import Supabase

/// Repository for profile-related database operations
final class ProfileRepository {
    private let supabase = SupabaseManager.shared.client

    /// Fetch a profile by ID
    func fetchProfile(userId: UUID) async throws -> Profile {
        try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
    }

    /// Fetch a profile by username
    func fetchProfileByUsername(username: String) async throws -> Profile? {
        let profiles: [Profile] = try await supabase
            .from("profiles")
            .select()
            .ilike("username", pattern: username)
            .limit(1)
            .execute()
            .value
        return profiles.first
    }

    /// Search profiles by name or username
    func searchProfiles(query: String, limit: Int = 20) async throws -> [Profile] {
        try await supabase
            .from("profiles")
            .select()
            .or("username.ilike.%\(query)%,full_name.ilike.%\(query)%")
            .limit(limit)
            .execute()
            .value
    }
}
