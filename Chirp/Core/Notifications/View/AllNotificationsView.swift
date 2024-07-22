//
//  AllNotifications.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202425.11.2023.
//

import SwiftUI

struct AllNotificationsView: View {
    var body: some View {
        ScrollView{
    
            ForEach(notifications, id: \.title) { notification in
                NotificationCard(notification: notification)
                Divider()
            }
        }
        .padding(.top, 20)
    }
}

#Preview {
    AllNotificationsView()
}
