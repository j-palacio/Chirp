//
//  NotificationsScreenTabs.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202425.11.2023.
//

import SwiftUI

struct NotificationsScreenTabs: View {
    @State var currentTab: Int = 0
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            TabBarViewNotifications(currentTab: self.$currentTab)
            
            TabView(selection: self.$currentTab) {
                AllNotificationsView().tag(0)
                VerifiedNotificationsView().tag(1)
                MentionNotificationsView().tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .edgesIgnoringSafeArea(.all)
    }
}
struct TabBarViewNotifications: View {
    @Binding var currentTab: Int
    @Namespace var namespace
    
    var tabBarOptions: [String] = ["All", "Verified", "Mentions"]
    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(zip(self.tabBarOptions.indices,
                              self.tabBarOptions)),
                    id: \.0,
                    content: {
                index, name in
                TabBarItemNotifications(currentTab: self.$currentTab,
                           namespace: namespace.self,
                           tabBarItemName: name,
                           tab: index)
                
            })
        }
        .padding(.horizontal)
        .frame(height: 30)
    }
}

struct TabBarItemNotifications: View {
    @Binding var currentTab: Int
    let namespace: Namespace.ID
    
    var tabBarItemName: String
    var tab: Int
    
    var body: some View {
        Button {
            self.currentTab = tab
        } label: {
            VStack {
                Spacer()
                Text(tabBarItemName)
            
                if currentTab == tab {
                    Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0))
                        .frame(height: 2)
                        .matchedGeometryEffect(id: "underline",
                                               in: namespace,
                                               properties: .frame)
                } else {
                    Color.clear.frame(height: 2)
                }
            }
            .animation(.spring(), value: self.currentTab)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NotificationsScreenTabs()
}

