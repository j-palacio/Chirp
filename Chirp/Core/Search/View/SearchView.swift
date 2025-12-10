//
//  SearchView.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202424.11.2023.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var showMenu: Bool

    @State private var searchText: String = ""
    @State private var searchResults: [Profile] = []
    @State private var isSearching = false
    @State private var hasSearched = false

    private let profileRepository = ProfileRepository()

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // Header with search bar
            ViewHeader(view: "search", searchText: $searchText, showMenu: $showMenu)
            Divider()

            // Content based on search state
            if searchText.isEmpty {
                // Show trending/explore view when not searching
                TrendsView()
            } else {
                // Show search results
                if isSearching {
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Searching...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        Spacer()
                    }
                } else if searchResults.isEmpty && hasSearched {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No results for \"\(searchText)\"")
                            .font(.headline)
                        Text("Try searching for something else")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(searchResults) { profile in
                                SearchResultRow(profile: profile)
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: searchText) { _, newValue in
            Task {
                await performSearch(query: newValue)
            }
        }
    }

    private func performSearch(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            hasSearched = false
            return
        }

        // Debounce - wait a bit before searching
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        // Check if query changed during sleep
        guard query == searchText else { return }

        isSearching = true

        do {
            let results = try await profileRepository.searchProfiles(query: query)
            // Only update if query is still the same
            if query == searchText {
                searchResults = results
                hasSearched = true
            }
        } catch {
            print("Search error: \(error)")
        }

        isSearching = false
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let profile: Profile
    @EnvironmentObject var authManager: AuthManager
    @State private var showProfile = false

    private let twitterBlue = Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0))

    var body: some View {
        Button {
            showProfile = true
        } label: {
            HStack(spacing: 12) {
                // Avatar
                AsyncImage(url: URL(string: profile.avatarUrl ?? "")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                    }
                }

                // User info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(profile.fullName ?? "Unknown")
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        if profile.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(twitterBlue)
                                .font(.caption)
                        }

                        if profile.isCuratedVoice {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                    }

                    Text("@\(profile.username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let bio = profile.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showProfile) {
            ProfileView(profileToShow: profile)
                .environmentObject(authManager)
        }
    }
}

//#Preview {
//    SearchView()
//}
