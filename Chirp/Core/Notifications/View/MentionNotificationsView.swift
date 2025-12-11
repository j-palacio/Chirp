//
//  MentionNotificationsView.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202425.11.2023.
//

import SwiftUI

struct MentionNotificationsView: View {
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
                        Task { await loadMentions() }
                    }
                    Spacer()
                }
            } else if notifications.isEmpty {
                VStack(alignment: .center, spacing: 12) {
                    Spacer()
                    Image(systemName: "at")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("Join the conversation")
                        .font(.headline)
                    Text("When someone mentions you in a post, you'll see it here.")
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
                    await loadMentions()
                }
            }
        }
        .task {
            await loadMentions()
        }
    }

    private func loadMentions() async {
        guard let userId = authManager.currentUser?.id else { return }

        isLoading = notifications.isEmpty
        error = nil

        do {
            notifications = try await repository.fetchMentions(userId: userId)
            isLoading = false
        } catch {
            self.error = "Failed to load mentions"
            isLoading = false
            print("Error loading mentions: \(error)")
        }
    }

    private func handleNotificationTap(_ notification: AppNotification) {
        Task {
            try? await repository.markAsRead(notificationId: notification.id)
        }
    }
}

#Preview {
    MentionNotificationsView()
        .environmentObject(AuthManager())
}
