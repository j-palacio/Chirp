//
//  MentionNotificationsView.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202425.11.2023.
//

import SwiftUI

struct MentionNotificationsView: View {
    var body: some View {
        VStack(alignment: .leading){
            Text("Join the conversation")
                .font(.title)
                .fontWeight(.black)
            
            Text("When a twitter user mentions you in a post or a answer, you will see that here.")
                .font(.callout)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(.leading)
        .padding(.trailing)
        .padding(.top, 10)
        
     
        
    }
}

#Preview {
    MentionNotificationsView()
}
