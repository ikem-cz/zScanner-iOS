//
//  StatusNetworkModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 03/09/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

struct TokenNetworkModel: Encodable {
    var token: String
}

struct StatusResponseNetworkModel: Decodable {
    var status: SeaCatLoginStatus
}

struct SeaCatLoginStatus: Decodable {
    var cert: Bool
    var username: Bool
    var password: Bool
}
