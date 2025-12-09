//
//  NotificationsView.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202424.11.2023.
//

import SwiftUI

struct NotificationsView: View {
    
    @Binding var showMenu : Bool
    
    var body: some View {
        VStack(alignment: .center) {
            //header
            ViewHeader(view: "notification", searchText: .constant(""), showMenu: $showMenu)
            Divider()
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

//#Preview {
//    NotificationsView()
//}
