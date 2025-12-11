//
//  NotificationCard.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.2024
//

import SwiftUI

struct NotificationCard: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Notification type icon on the left (small, colored)
            Image(systemName: notification.iconName)
                .foregroundColor(notification.iconColor)
                .font(.system(size: 18, weight: .bold))
                .frame(width: 28, height: 28, alignment: .trailing)

            // Content column
            VStack(alignment: .leading, spacing: 8) {
                // Actor avatar (larger than icon)
                AsyncImage(url: URL(string: notification.actor?.avatarUrl ?? "")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else if phase.error != nil {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 18))
                            )
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.6)
                            )
                    }
                }

                // Username + action text
                Group {
                    Text(notification.actor?.fullName ?? "Someone")
                        .fontWeight(.bold) +
                    Text(" \(notification.actionText)")
                }
                .font(.subheadline)

                // Post preview (if applicable)
                if let post = notification.post {
                    Text(post.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Timestamp
            Text(notification.relativeTimestamp())
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(notification.isRead ? Color.clear : Color.blue.opacity(0.05))
        .contentShape(Rectangle())
    }
}

// MARK: - Legacy NotificationCard (for backward compatibility during transition)

struct LegacyNotificationCard: View {
    let notification: NotificationModel

    var body: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundColor(.purple)
                .imageScale(.large)
                .frame(width: 30, height: 30)
                .padding(.leading)

            VStack(alignment: .leading) {
                AsyncImage(url: URL(string: "https://i.pravatar.cc/40")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .cornerRadius(99)
                    } else if phase.error != nil {
                        Color.red
                    } else {
                        ProgressView()
                    }
                }

                Text(notification.title)
                    .fontWeight(.semibold)

                Text(notification.description)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
            .frame(width: 30, height: 30)
        }
    }
}
