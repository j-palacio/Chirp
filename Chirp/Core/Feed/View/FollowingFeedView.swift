//
//  FollowingFeedView.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202425.11.2023.
//

import SwiftUI

struct FollowingFeedView: View {
    var body: some View {
       ScrollViewReaderFeed(mockData: ArraySlice(mockData), sliceArray: true)
    }
}

#Preview {
    FollowingFeedView()
}
