//
//  TabView.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202424.11.2023.
//

import SwiftUI


struct TabNavigationView: View {
    @EnvironmentObject var authManager: AuthManager

    @State var showMenu: Bool = false
    @State var showComposeSheet: Bool = false

    //offsets
    @State var offset: CGFloat = 0
    @State var lastStoredOffset: CGFloat = 0

    var body: some View {

        let sideBarWidth = getRect().width - 90;


        NavigationStack{
            HStack(spacing: -90){
                //Side menu
                SlideMenuView(showMenu: $showMenu)

                //tab view
                TabView {
                    FeedScreen(showMenu: $showMenu)
                        .tabItem {
                            Image(systemName: "house")
                        }

                    SearchView(showMenu: $showMenu)
                        .tabItem {
                            Image(systemName: "magnifyingglass")
                        }

                    CommunityView(showMenu: $showMenu)
                        .tabItem {
                            Image(systemName: "person.2.fill")
                        }

                    NotificationsView(showMenu: $showMenu)
                        .tabItem {
                            Image(systemName: "bell")
                        }

                    MessagesView(showMenu: $showMenu)
                        .tabItem {
                            Image(systemName: "envelope")
                        }
                }
                .overlay(
                    Rectangle()
                        .fill(
                            Color.primary
                                .opacity(Double((offset / sideBarWidth) / 5))
                        )
                        .ignoresSafeArea(.container, edges: .vertical)
                        .onTapGesture{
                            withAnimation{
                                showMenu.toggle()
                            }
                        }
                )

            }
            .frame(width: getRect().width + sideBarWidth)
            .offset(x: -sideBarWidth / 2)
            .offset(x: offset > 0 ? offset : 0)

        }
        .overlay(alignment: .bottomTrailing) {
            // Floating compose button
            if !showMenu {
                Button {
                    showComposeSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0)))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding(.trailing, 10)
                .padding(.bottom, 60)
            }
        }
        .animation(.bouncy, value: offset == 0)
        .onChange(of: showMenu) { newValue in
            if showMenu && offset == 0 {
                offset = sideBarWidth
            }

            if !showMenu && offset == sideBarWidth {
                offset = 0
                lastStoredOffset = 0
            }
        }
        .sheet(isPresented: $showComposeSheet) {
            ComposePostView { newPost in
                // Post created - feed will refresh automatically
            }
            .environmentObject(authManager)
        }

    }
}

#Preview {
    TabNavigationView()
        .environmentObject(AuthManager())
}
