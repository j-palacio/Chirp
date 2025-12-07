//
//  PostDetailView.swift
//  Chirp
//
//  Created by Claude on 07.12.2025.
//

import SwiftUI

struct PostDetailView: View {
    let post: Post
    @Binding var commentCount: Int
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var comments: [Comment] = []
    @State private var newComment = ""
    @State private var isLoading = true
    @State private var isPosting = false
    @State private var errorMessage: String?

    private let postRepository = PostRepository()
    private let twitterBlue = Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0))

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Original post
                        postHeader
                        Divider()

                        // Comments section
                        if isLoading {
                            ProgressView()
                                .padding(.top, 40)
                        } else if comments.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("No comments yet")
                                    .font(.headline)
                                Text("Be the first to reply!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 40)
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(comments) { comment in
                                    CommentRowView(comment: comment)
                                    Divider()
                                }
                            }
                        }
                    }
                }

                // Comment input
                Divider()
                commentInput
            }
            .navigationTitle("Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadComments()
            }
        }
    }

    private var postHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author info
            HStack(spacing: 10) {
                AsyncImage(url: URL(string: post.author?.avatarUrl ?? "https://i.pravatar.cc/48")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 48, height: 48)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(post.author?.fullName ?? "Unknown")
                            .fontWeight(.bold)
                        if post.author?.isVerified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(twitterBlue)
                                .font(.caption)
                        }
                        if post.author?.isCuratedVoice == true {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }
                    Text("@\(post.author?.username ?? "unknown")")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }

                Spacer()
            }

            // Post content
            Text(post.content)
                .font(.body)

            // Post image
            if let imageUrl = post.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 250)
                            .cornerRadius(12)
                            .clipped()
                    }
                }
            }

            // Timestamp
            Text(post.createdAt, style: .date) + Text(" at ") + Text(post.createdAt, style: .time)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Stats
            HStack(spacing: 16) {
                Label("\(post.repostCount) Reposts", systemImage: "arrow.2.squarepath")
                Label("\(post.likeCount) Likes", systemImage: "heart")
                Label("\(post.viewCount) Views", systemImage: "chart.bar.fill")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
    }

    private var commentInput: some View {
        HStack(spacing: 12) {
            // User avatar
            if let avatarUrl = authManager.currentProfile?.avatarUrl,
               let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: 36, height: 36)
            }

            // Text field
            TextField("Post your reply", text: $newComment)
                .textFieldStyle(.plain)

            // Post button
            Button {
                postComment()
            } label: {
                if isPosting {
                    ProgressView()
                        .tint(twitterBlue)
                } else {
                    Text("Reply")
                        .fontWeight(.semibold)
                        .foregroundColor(newComment.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : twitterBlue)
                }
            }
            .disabled(newComment.trimmingCharacters(in: .whitespaces).isEmpty || isPosting)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }

    private func loadComments() async {
        isLoading = true
        do {
            comments = try await postRepository.fetchComments(postId: post.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func postComment() {
        guard let userId = authManager.currentUser?.id else { return }
        let content = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        isPosting = true

        Task {
            do {
                let comment = try await postRepository.createComment(
                    postId: post.id,
                    authorId: userId,
                    content: content
                )
                await MainActor.run {
                    comments.append(comment)
                    commentCount += 1
                    newComment = ""
                    isPosting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isPosting = false
                }
            }
        }
    }
}

// MARK: - Comment Row View

struct CommentRowView: View {
    let comment: Comment
    private let twitterBlue = Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0))

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Avatar
            AsyncImage(url: URL(string: comment.author?.avatarUrl ?? "https://i.pravatar.cc/40")) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                // Author info
                HStack(spacing: 4) {
                    Text(comment.author?.fullName ?? "Unknown")
                        .fontWeight(.semibold)
                        .font(.subheadline)

                    if comment.author?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(twitterBlue)
                            .font(.caption2)
                    }

                    Text("@\(comment.author?.username ?? "unknown")")
                        .foregroundColor(.secondary)
                        .font(.subheadline)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(comment.relativeTimestamp())
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }

                // Comment content
                Text(comment.content)
                    .font(.subheadline)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    PostDetailView(
        post: Post(
            id: UUID(),
            authorId: UUID(),
            content: "Test post content",
            imageUrl: nil,
            likeCount: 5,
            commentCount: 2,
            repostCount: 1,
            viewCount: 100,
            isCurated: false,
            moderationStatus: "approved",
            createdAt: Date(),
            updatedAt: Date(),
            author: nil
        ),
        commentCount: .constant(2)
    )
    .environmentObject(AuthManager())
}
