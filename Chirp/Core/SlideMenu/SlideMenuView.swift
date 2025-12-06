//
//  SlideMenuView.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202425.11.2023.
//

import SwiftUI

struct SlideMenuView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var appearanceTheme = false
    @Binding var showMenu : Bool

    var body: some View {

        VStack(alignment: .leading, spacing: 0 ){

            //header container
            VStack(alignment: .leading, spacing: 10){


                NavigationLink{
                    ProfileView()
                        .toolbar(.hidden)

                } label: {
                    //user profile picture
                    if let avatarUrl = authManager.currentProfile?.avatarUrl,
                       let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 55, height: 55)
                                    .cornerRadius(99)
                            } else {
                                defaultAvatar
                            }
                        }
                    } else {
                        defaultAvatar
                    }
                }



                //user name
                Text(authManager.currentProfile?.fullName ?? "User")
                    .font(.title2.bold())

                //user username
                Text("@\(authManager.currentProfile?.username ?? "user")")
                    .font(.callout)
                    .foregroundStyle(Color.gray)

                //user statistics (following and followers
                HStack{
                    //following
                    Button{

                    } label : {
                        Label{
                            Text("Following")
                                .foregroundStyle(Color.gray)
                        } icon: {
                            Text("\(authManager.currentProfile?.followingCount ?? 0)")
                                .fontWeight(.semibold)
                        }

                    }

                    //followers
                    Button{

                    } label : {
                        Label{
                            Text("Followers")
                                .foregroundStyle(Color.gray)
                        } icon: {
                            Text(formatCount(authManager.currentProfile?.followerCount ?? 0))
                                .fontWeight(.semibold)


                        }

                    }

                }
                .foregroundColor(.primary)
                .font(.subheadline)

            }
            .padding(.horizontal)
            .padding(.leading)
            
            //menu options
            ScrollView(.vertical, showsIndicators: false){
                VStack(alignment: .leading, spacing: 25){
                    //Tab buttons
                    TabButton(title: "Profile", image: "person", destination: ProfileView())
                    
                    TabButton(title: "Bookmarks", image: "bookmark", destination: ProfileView())
                    
                    TabButton(title: "Messages", image: "envelope", destination: ProfileView())
                    
                    TabButton(title: "Discover", image: "number", destination: ProfileView())
                    
                    TabButton(title: "Lists", image: "list.bullet.rectangle.portrait", destination: ProfileView())
                    
                    TabButton(title: "Monetization", image: "dollarsign.circle", destination: ProfileView())
                    
                    //twitter ads
                    Divider()
                    
                    TabButton(title: "Twitter Ads", image: "square.and.arrow.up", destination: ProfileView())
                    
                }
                .padding()
                .padding(.leading)
                .padding(.top, 30)
                
                
                
            }
            // Bottom section with theme toggle and logout
            VStack(spacing: 16) {
                Divider()

                HStack {
                    // Theme toggle
                    Button {
                        appearanceTheme.toggle()
                    } label: {
                        Image(systemName: appearanceTheme ? "moon" : "sun.min")
                            .imageScale(.large)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    // Logout button
                    Button {
                        Task {
                            try? await authManager.signOut()
                            showMenu = false
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log out")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .padding(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)


        }
        .padding(.vertical)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(width: getRect().width - 90)
        .frame(maxHeight: .infinity)
        .background(
            Color.primary
                .opacity(0.04)
                .ignoresSafeArea(.container, edges: .vertical)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helper Views

    private var defaultAvatar: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 55, height: 55)
            .foregroundColor(.gray)
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
    
    @ViewBuilder
    func TabButton<Destination: View>(title: String, image: String, destination: Destination) -> some View {
        NavigationLink(destination: destination.toolbar(.hidden)) {
            HStack(spacing: 14) {
                Image(systemName: image)
                    .imageScale(.large)
                    .frame(width: 30)
                Text(title)
                    .fontWeight(.bold)
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
   
    }


}

extension View {
    func getRect() -> CGRect{
        return UIScreen.main.bounds
    }
}

//#Preview {
//    SlideMenuView()
//}
