//
//  ForYouFeedView.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202425.11.2023.
//

import SwiftUI

struct ForYouFeedView: View {
    
    var body: some View {
        //loop through mock data and display posts
        ScrollViewReaderFeed(mockData: ArraySlice(mockData), sliceArray: false)
    }
}
#Preview {
    ForYouFeedView()
}
