//
//  ProfileView.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202427.11.2023.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager

    // Optional: profile to display (if nil, shows current user)
    var profileToShow: Profile?

    @State var offset: CGFloat = 0

    //Dark mode
    @Environment(\.colorScheme) var colorScheme

    @State var currentTab = "Tweets"

    //smooth slide animation
    @Namespace var animation

    @State var titleHeaderOffset: CGFloat = 0

    @State private var fadeInOpacity: Double = 0.0
    @State private var isFollowing = false
    @State private var isProcessingFollow = false
    @State private var followerCount: Int = 0

    @Environment(\.presentationMode) var presentationMode

    private let postRepository = PostRepository()
    private let twitterBlue = Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0))

    // The profile being displayed (either profileToShow or currentProfile)
    private var displayProfile: Profile? {
        profileToShow ?? authManager.currentProfile
    }

    // Check if viewing own profile
    private var isOwnProfile: Bool {
        guard let displayId = displayProfile?.id,
              let currentId = authManager.currentUser?.id else { return true }
        return displayId == currentId
    }

    // Helper to format counts
    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }

    // Format joined date
    private func formatJoinedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return "Joined \(formatter.string(from: date))"
    }
    
    //Profile shrinking effect...
    private func getOffset() -> CGFloat{
        
        let progress = (-offset / 50) * 20
        
        return progress <= 20 ? progress : 20
        
    }
    
    private func getScale() -> CGFloat{
        
        let progress = -offset / 50
        
        let scale = 1.8 - (progress < 1.0 ? progress : 1)
        
        return scale < 1 ? scale : 1
    }
    
    private func blurViewOpacityNegativeY() -> Double {
        
        let progress = -(offset + 50) / 120
        
        return Double(-offset > 50 ? progress : 0)
    }
    
    private func blurViewOpacityPositiveY() -> Double {
        
        let progress = (offset + 30) / 120
        
        return Double(offset > 0 ? progress : 0)
    }
    
    private func calculateOffset() -> CGFloat {
        let easeInThreshold: CGFloat = 170
        let maxOffset: CGFloat = 50
        let startingOffset: CGFloat = 100
        
        guard -offset >= easeInThreshold else {
            return startingOffset // Default offset when not easing in
        }
        
        let normalizedOffset = max(0, min(1, (-offset - easeInThreshold) / (easeInThreshold - 142)))
        let easedOffset = maxOffset * (1 - pow(1 - normalizedOffset, 3)) // Cubic ease-in function
        
        return startingOffset - min(easedOffset, maxOffset)
    }
    
    
    
    var body: some View {
        
        ScrollView(.vertical, showsIndicators: false, content: {
            VStack{
                //Header view
                GeometryReader{ proxy -> AnyView in
                    
                    //sticky header
                    let minY = proxy.frame(in: .global).minY
                    
                    DispatchQueue.main.async {
                        self.offset = minY
                    }
                    
                    return AnyView(
                        
                        ZStack{
                            //Banner
                            if let bannerUrl = displayProfile?.bannerUrl,
                               let url = URL(string: bannerUrl) {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: getRect().width, height: minY > 0 ? 150 + minY : 150, alignment: .center)
                                            .cornerRadius(0)
                                    } else {
                                        Rectangle()
                                            .fill(twitterBlue)
                                            .frame(width: getRect().width, height: minY > 0 ? 150 + minY : 150, alignment: .center)
                                    }
                                }
                            } else {
                                Rectangle()
                                    .fill(twitterBlue)
                                    .frame(width: getRect().width, height: minY > 0 ? 150 + minY : 150, alignment: .center)
                            }


                            if minY < 0 {BlurView()
                                .opacity(blurViewOpacityNegativeY())}
                            else {BlurView()
                                .opacity(blurViewOpacityPositiveY())}


                            //Title view
                            VStack(alignment: .leading, spacing: -1){

                                Text(displayProfile?.fullName ?? "User")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)


                                Text("0 posts")
                                    .foregroundColor(.white)

                            }
                            .opacity((offset >= 0 || (-offset >= 0 && -offset <= 170)) ? 0 : (((-offset - 170) / 20) * 20) * 0.05)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 60)
                            .offset(y: calculateOffset())
                            
                            
                            
                            HStack {
                                // Back button
                                Button{
                                    presentationMode.wrappedValue.dismiss()
                                } label : {
                                    Image(systemName: "arrow.left")
                                        .foregroundStyle(.white)
                                    //.imageScale(.large)
                                        .padding(8)
                                        .background(Color(.systemGray2).opacity(0.4))
                                        .clipShape(Circle())
                                }
                                
                                Spacer()
                                
                                //search button
                                Button{
                                    
                                } label : {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(.white)
                                    //.imageScale(.large)
                                        .padding(7)
                                        .background(Color(.systemGray2).opacity(0.4))
                                        .clipShape(Circle())
                                }
                                
                                // More button
                                Button{
                                    
                                } label : {
                                    Image(systemName: "ellipsis")
                                        .foregroundStyle(.white)
                                    // .imageScale(.large)
                                        .padding(13)
                                        .background(Color(.systemGray2).opacity(0.4))
                                        .clipShape(Circle())
                                }
                                
                                
                                
                                
                            }
                            .padding(.top, 15)
                            .padding(.leading)
                            .padding(.trailing)
                            .position(x: getRect().width / 2, y: 90)
                            .offset(y: -minY > 0 ? (-minY > 22 ? 22 : -minY + 1) : 0)
                            
                            
                        }
                        //stretchy header
                            .frame(height: minY > 0 ? 150 + minY : nil)
                            .offset(y: minY > 0 ? -minY : -minY < 50 ? 0 : -minY - 50)
                    )
                }
                .frame(height: 150)
                .zIndex(1)
                
                //Profile image...
                VStack (spacing: -5){
                    HStack{

                        //image
                        Group {
                            if let avatarUrl = displayProfile?.avatarUrl,
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
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(width: 75, height: 75)
                        .clipShape(Circle())
                        .padding(5)
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .clipShape(Circle())
                        .offset(y: offset < 0 ? getOffset() - 20 : -20)
                        .scaleEffect(getScale())

                        Spacer()

                        if isOwnProfile {
                            // Edit profile button for own profile
                            Button {
                                // TODO: Edit profile action
                            } label: {
                                Text("Edit profile")
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .foregroundColor(.primary)
                                    .background(
                                        Capsule()
                                            .stroke(Color(.systemGray3), lineWidth: 1)
                                    )
                            }
                        } else {
                            // Follow/Unfollow button for other users
                            Button {
                                toggleFollow()
                            } label: {
                                if isProcessingFollow {
                                    ProgressView()
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                } else {
                                    Text(isFollowing ? "Following" : "Follow")
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .foregroundColor(isFollowing ? .primary : .white)
                                        .background(isFollowing ? Color.clear : twitterBlue)
                                        .background(
                                            Capsule()
                                                .stroke(isFollowing ? Color(.systemGray3) : Color.clear, lineWidth: 1)
                                        )
                                        .clipShape(Capsule())
                                }
                            }
                            .disabled(isProcessingFollow)
                        }

                    }
                    .padding(.top, -18)
                    
                    //Profile data
                    VStack(alignment: .leading, spacing: 5){

                        HStack {
                            //Full name
                            Text(displayProfile?.fullName ?? "User")
                                .font(.title2)
                                .fontWeight(.bold)
                            //Verified badge
                            if displayProfile?.isVerified == true {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(twitterBlue)
                                    .font(.title3)
                            }
                            //Curated voice badge
                            if displayProfile?.isCuratedVoice == true {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }

                        }
                        //username
                        Text("@\(displayProfile?.username ?? "user")")
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        // Bio
                        if let bio = displayProfile?.bio, !bio.isEmpty {
                            Text(bio)
                                .padding(.top, 2)
                        }

                        //Joined date
                        HStack{
                            //joined date
                            if let createdAt = displayProfile?.createdAt {
                                Label(
                                    title: { Text(formatJoinedDate(createdAt)) },
                                    icon: { Image(systemName: "calendar") }
                                )
                            }
                        }
                        .padding(.top, 6)
                        .foregroundStyle(.secondary)
                        .font(.callout)

                        //User stats
                        HStack{
                            //following
                            Button{
                            } label : {

                                Text("\(displayProfile?.followingCount ?? 0)")
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                    .fontWeight(.semibold)

                                Text("Following")
                                    .foregroundStyle(Color(.systemGray2))

                            }
                            //followers
                            Button{
                            } label : {
                                Text(formatCount(followerCount))
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                    .fontWeight(.semibold)
                                Text("Followers")
                                    .foregroundStyle(Color(.systemGray2))

                            }
                        }


                    }
                    
                    //custom segmented menu
                    CustomTabsBar(currentTab: $currentTab, animation: animation)
                    
                    VStack{
                        ForEach(profileTweetsMockData, id: \.postId) { post in
                            ProfilePostViewModel(post: post)
                            Divider()
                        }
                    }
                    .animation(.bouncy)
                    .padding(.top, 25)
                    .zIndex(0)
                    
                }
                .padding(.horizontal)
                .zIndex(-offset > 50 ? 0 : 1)
                
            }
        })
        .ignoresSafeArea(.all, edges: .top)
        .task {
            await checkFollowStatus()
            initializeFollowerCount()
        }
    }

    // MARK: - Follow Actions

    private func initializeFollowerCount() {
        followerCount = displayProfile?.followerCount ?? 0
    }

    private func checkFollowStatus() async {
        guard !isOwnProfile,
              let currentUserId = authManager.currentUser?.id,
              let profileId = displayProfile?.id else { return }

        do {
            isFollowing = try await postRepository.isFollowing(followerId: currentUserId, followingId: profileId)
        } catch {
            print("Error checking follow status: \(error)")
        }
    }

    private func toggleFollow() {
        guard !isProcessingFollow,
              let currentUserId = authManager.currentUser?.id,
              let profileId = displayProfile?.id else { return }

        isProcessingFollow = true

        // Optimistic update
        isFollowing.toggle()
        followerCount += isFollowing ? 1 : -1

        Task {
            do {
                if isFollowing {
                    try await postRepository.followUser(followerId: currentUserId, followingId: profileId)
                } else {
                    try await postRepository.unfollowUser(followerId: currentUserId, followingId: profileId)
                }
            } catch {
                // Revert on error
                isFollowing.toggle()
                followerCount += isFollowing ? 1 : -1
                print("Error toggling follow: \(error)")
            }
            isProcessingFollow = false
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
