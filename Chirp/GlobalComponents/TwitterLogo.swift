//
//  TwitterLogo.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202424.11.2023.
//

import SwiftUI

struct TwitterLogo: View {
    var frameWidth : CGFloat
    var paddingTop : CGFloat
    var body: some View {
        
        Image("TwitterLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: frameWidth)
            .padding(.top, paddingTop)
          
      
    }
}

#Preview {
    TwitterLogo(frameWidth: 30, paddingTop: 15)
}
