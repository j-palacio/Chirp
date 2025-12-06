//
//  ComposePostView.swift
//  Chirp
//
//  Created by Juan Palacio on 06.12.2024.
//

import SwiftUI

struct ComposePostView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var postContent = ""
    @State private var isPosting = false
    @State private var showError = false
    @State private var errorMessage = ""

    let onPostCreated: ((Post) -> Void)?

    init(onPostCreated: ((Post) -> Void)? = nil) {
        self.onPostCreated = onPostCreated
    }

    private var canPost: Bool {
        !postContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isPosting
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Compose area
                HStack(alignment: .top, spacing: 12) {
                    // Avatar
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
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                            .frame(width: 40, height: 40)
                    }

                    // Text input
                    TextField("What's happening?", text: $postContent, axis: .vertical)
                        .font(.body)
                        .lineLimit(10...20)
                }
                .padding()

                Spacer()

                // Bottom toolbar
                Divider()
                HStack {
                    // Media buttons (placeholder for now)
                    Button { } label: {
                        Image(systemName: "photo")
                            .foregroundColor(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0)))
                    }

                    Button { } label: {
                        Image(systemName: "gif")
                            .foregroundColor(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0)))
                    }

                    Button { } label: {
                        Image(systemName: "list.bullet")
                            .foregroundColor(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0)))
                    }

                    Button { } label: {
                        Image(systemName: "location")
                            .foregroundColor(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0)))
                    }

                    Spacer()

                    // Character count
                    Text("\(280 - postContent.count)")
                        .font(.caption)
                        .foregroundColor(postContent.count > 280 ? .red : .secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        createPost()
                    } label: {
                        if isPosting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Post")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!canPost || postContent.count > 280)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(canPost && postContent.count <= 280 ? Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0)) : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func createPost() {
        guard let userId = authManager.currentUser?.id else {
            errorMessage = "You must be logged in to post"
            showError = true
            return
        }

        let content = postContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        isPosting = true

        Task {
            do {
                let postRepository = PostRepository()
                let post = try await postRepository.createPost(
                    authorId: userId,
                    content: content,
                    imageUrl: nil
                )

                await MainActor.run {
                    onPostCreated?(post)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isPosting = false
                }
            }
        }
    }
}

#Preview {
    ComposePostView()
        .environmentObject(AuthManager())
}
