//
//  UserModel.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202426.11.2023.
//

import Foundation

final class UserModel {
    let userId: String
    let username: String
    let fullName: String

    init(userId: String, username: String, fullName: String) {
        self.userId = userId
        self.username = username
        self.fullName = fullName
    }
}
