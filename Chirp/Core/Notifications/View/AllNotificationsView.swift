//
//  AllNotificationsView.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202425.11.2023.
//

import SwiftUI

struct AllNotificationsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = false
    @State private var error: String?

    private let repository = NotificationRepository()

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
            } else if notifications.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "bell.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No notifications yet")
                        .font(.headline)
                    Text("When someone interacts with your posts, you'll see it here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(notifications) { notification in
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
            notifications = try await repository.fetchNotifications(userId: userId)
            isLoading = false
        } catch {
            self.error = "Failed to load notifications"
            isLoading = false
            print("Error loading notifications: \(error)")
        }
    }

    private func handleNotificationTap(_ notification: AppNotification) {
        // Mark as read
        Task {
            try? await repository.markAsRead(notificationId: notification.id)
            // Update local state
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                var updated = notifications[index]
                // Note: Can't mutate directly due to let, would need to reload or use different approach
            }
        }

        // TODO: Navigate to relevant content based on notification type
        // - follow: go to profile
        // - like/comment/repost: go to post
        // - mention: go to post
    }
}

#Preview {
    AllNotificationsView()
        .environmentObject(AuthManager())
}
