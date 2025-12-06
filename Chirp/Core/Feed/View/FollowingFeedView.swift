//
//  FollowingFeedView.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202425.11.2023.
//

import SwiftUI

struct FollowingFeedView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = FeedViewModel()

    var body: some View {
        Group {
            if authManager.currentUser == nil {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "person.2")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("Sign in to see posts")
                        .font(.headline)
                    Text("Follow people to see their posts here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else if viewModel.isLoadingFollowing && viewModel.followingPosts.isEmpty {
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading posts...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
            } else if viewModel.followingPosts.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "person.2")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No posts from people you follow")
                        .font(.headline)
                    Text("When you follow people, their posts will show up here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Spacer()
                }
            } else {
                FeedScrollView(
                    posts: viewModel.followingPosts,
                    isLoading: viewModel.isLoadingFollowing,
                    hasMore: viewModel.hasMoreFollowing,
                    onLoadMore: {
                        Task {
                            if let userId = authManager.currentUser?.id {
                                await viewModel.loadMoreFollowing(userId: userId)
                            }
                        }
                    },
                    onRefresh: {
                        Task {
                            if let userId = authManager.currentUser?.id {
                                await viewModel.refreshFollowingFeed(userId: userId)
                            }
                        }
                    }
                )
            }
        }
        .task {
            if let userId = authManager.currentUser?.id, viewModel.followingPosts.isEmpty {
                await viewModel.fetchFollowingFeed(userId: userId, refresh: true)
            }
        }
    }
}

#Preview {
    FollowingFeedView()
        .environmentObject(AuthManager())
}
