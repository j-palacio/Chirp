//
//  Chirp.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202420.11.2023.
//

import SwiftUI
import Supabase

@main
struct Chirp_App: App {
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .onOpenURL { url in
                    // Handle OAuth callback from Google/Apple sign-in
                    Task {
                        do {
                            try await SupabaseManager.shared.client.auth.session(from: url)
                        } catch {
                            print("OAuth callback error: \(error)")
                        }
                    }
                }
        }
    }
}

// MARK: - Root View (Auth Routing)

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashAnimationView {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSplash = false
                    }
                }
            } else if authManager.isLoading {
                LoadingView()
            } else if authManager.isAuthenticated {
                TabNavigationView()
            } else {
                NavigationView {
                    SignUpView()
                }
            }
        }
    }
}

// MARK: - Splash Animation View

struct SplashAnimationView: View {
    let onComplete: () -> Void

    @State private var animationState: AnimationState = .normal

    private func calculate() -> Double {
        switch animationState {
        case .compress:
            return 0.18
        case .expand:
            return 10.0
        case .normal:
            return 0.2
        }
    }

    var body: some View {
        VStack {
            Image("TwitterLogo")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.white)
                .scaleEffect(calculate())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0)))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring()) {
                    animationState = .compress
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.spring()) {
                            animationState = .expand
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onComplete()
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
