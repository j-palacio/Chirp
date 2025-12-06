import Foundation
import Supabase
import AuthenticationServices

/// Manages authentication state for the app
@MainActor
final class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var currentProfile: Profile?
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var authError: String?

    private let supabase = SupabaseManager.shared.client

    init() {
        Task {
            await checkSession()
            await listenToAuthChanges()
        }
    }

    // MARK: - Session Management

    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            self.currentUser = session.user
            self.isAuthenticated = true
            await fetchProfile()
        } catch {
            self.isAuthenticated = false
            self.currentUser = nil
        }
        self.isLoading = false
    }

    private func listenToAuthChanges() async {
        for await (event, session) in supabase.auth.authStateChanges {
            switch event {
            case .signedIn:
                self.currentUser = session?.user
                self.isAuthenticated = true
                await fetchProfile()
            case .signedOut:
                self.currentUser = nil
                self.currentProfile = nil
                self.isAuthenticated = false
            default:
                break
            }
        }
    }

    // MARK: - Email/Password Auth

    /// Sign in with email or username
    func signIn(identifier: String, password: String) async throws {
        authError = nil

        var email = identifier

        // If it doesn't look like an email, treat it as a username and look up the email
        if !identifier.contains("@") {
            guard let userEmail = try await lookupEmailByUsername(username: identifier) else {
                self.authError = "Username not found"
                throw AuthError.usernameNotFound
            }
            email = userEmail
        }

        do {
            let response = try await supabase.auth.signIn(email: email, password: password)
            self.currentUser = response.user
            self.isAuthenticated = true
            await fetchProfile()
        } catch {
            self.authError = error.localizedDescription
            throw error
        }
    }

    /// Look up email by username from profiles table
    private func lookupEmailByUsername(username: String) async throws -> String? {
        struct UserEmail: Decodable {
            let id: UUID
        }

        // Get user ID from profiles (case-insensitive)
        let profile: UserEmail? = try? await supabase
            .from("profiles")
            .select("id")
            .ilike("username", pattern: username)
            .single()
            .execute()
            .value

        guard let userId = profile?.id else { return nil }

        // Get email from auth.users (via RPC or direct query if allowed)
        struct AuthUser: Decodable {
            let email: String?
        }

        let authUser: AuthUser? = try? await supabase
            .from("users")
            .select("email")
            .eq("id", value: userId)
            .single()
            .execute()
            .value

        return authUser?.email
    }

    func signInWithEmail(email: String, password: String) async throws {
        try await signIn(identifier: email, password: password)
    }

    func signUpWithEmail(email: String, password: String, username: String, fullName: String) async throws {
        authError = nil
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: [
                    "username": .string(username),
                    "full_name": .string(fullName)
                ]
            )
            self.currentUser = response.user
            self.isAuthenticated = true
            await fetchProfile()
        } catch {
            self.authError = error.localizedDescription
            throw error
        }
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async throws {
        authError = nil
        do {
            try await supabase.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "chirp://auth/callback")
            )
        } catch {
            self.authError = error.localizedDescription
            throw error
        }
    }

    // MARK: - Apple Sign-In

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidToken
        }

        authError = nil
        do {
            let response = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: tokenString
                )
            )

            self.currentUser = response.user
            self.isAuthenticated = true

            // Check if profile exists, create if not
            let userId = response.user.id
            let existingProfile = try? await fetchProfileById(userId: userId)
            if existingProfile == nil {
                let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                let username = credential.email?.components(separatedBy: "@").first ?? "user_\(UUID().uuidString.prefix(8))"
                try await createProfile(userId: userId, username: username, fullName: fullName.isEmpty ? "User" : fullName)
            }

            await fetchProfile()
        } catch {
            self.authError = error.localizedDescription
            throw error
        }
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await supabase.auth.signOut()
        self.currentUser = nil
        self.currentProfile = nil
        self.isAuthenticated = false
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }

    // MARK: - Profile Management

    private func createProfile(userId: UUID, username: String, fullName: String) async throws {
        let profile = ProfileInsert(id: userId, username: username, fullName: fullName)
        try await supabase.from("profiles").insert(profile).execute()
    }

    func fetchProfile() async {
        guard let userId = currentUser?.id else { return }
        do {
            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            self.currentProfile = profile
        } catch {
            print("Failed to fetch profile: \(error)")
        }
    }

    private func fetchProfileById(userId: UUID) async throws -> Profile? {
        try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
    }

    func updateProfile(updates: ProfileUpdate) async throws {
        guard let userId = currentUser?.id else { return }
        let updated: Profile = try await supabase
            .from("profiles")
            .update(updates)
            .eq("id", value: userId)
            .select()
            .single()
            .execute()
            .value
        self.currentProfile = updated
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidToken
    case profileCreationFailed
    case usernameNotFound

    var errorDescription: String? {
        switch self {
        case .invalidToken:
            return "Invalid authentication token"
        case .profileCreationFailed:
            return "Failed to create user profile"
        case .usernameNotFound:
            return "Username not found"
        }
    }
}
