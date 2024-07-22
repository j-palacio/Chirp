//
//  TrendsModel.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202417.12.2023.
//

import Foundation

final class TrendsModel{
    let id: Int
    let category : String
    let trending : Bool
    let title : String
    let tweets : String
    init(id: Int, category: String, trending: Bool, title: String, tweets: String) {
        self.id = id
        self.category = category
        self.trending = trending
        self.title = title
        self.tweets = tweets
    }
}
