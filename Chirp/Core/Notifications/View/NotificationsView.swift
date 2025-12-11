//
//  NotificationsView.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202424.11.2023.
//

import SwiftUI

struct NotificationsView: View {
    @Binding var showMenu: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header (includes the tab bar via NotificationsScreenTabs)
            ViewHeader(view: "notification", searchText: .constant(""), showMenu: $showMenu)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    NotificationsView(showMenu: .constant(false))
        .environmentObject(AuthManager())
}
