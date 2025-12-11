//
//  VerifiedNotificationsView.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202425.11.2023.
//

import SwiftUI

struct VerifiedNotificationsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = false
    @State private var error: String?

    private let repository = NotificationRepository()

    // Filter notifications from verified users only
    var verifiedNotifications: [AppNotification] {
        notifications.filter { $0.actor?.isVerified == true }
    }

    var body: some View {
        Group {
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if let error = error {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task { await loadNotifications() }
                    }
                    Spacer()
                }
            } else if verifiedNotifications.isEmpty {
                VStack(spacing: 16) {
                    Spacer()

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0)))

                    VStack(alignment: .center, spacing: 10) {
                        Text("Nothing to see here yet")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Likes, mentions, reposts, and more from verified accounts will appear here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(verifiedNotifications) { notification in
                            NotificationCard(notification: notification)
                                .onTapGesture {
                                    handleNotificationTap(notification)
                                }
                            Divider()
                        }
                    }
                }
                .refreshable {
                    await loadNotifications()
                }
            }
        }
        .task {
            await loadNotifications()
        }
    }

    private func loadNotifications() async {
        guard let userId = authManager.currentUser?.id else { return }

        isLoading = notifications.isEmpty
        error = nil

        do {
            // Fetch all notifications and filter for verified actors client-side
            notifications = try await repository.fetchNotifications(userId: userId)
            isLoading = false
        } catch {
            self.error = "Failed to load notifications"
            isLoading = false
            print("Error loading verified notifications: \(error)")
        }
    }

    private func handleNotificationTap(_ notification: AppNotification) {
        Task {
            try? await repository.markAsRead(notificationId: notification.id)
        }
    }
}

#Preview {
    VerifiedNotificationsView()
        .environmentObject(AuthManager())
}
