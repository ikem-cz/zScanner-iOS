//
//  BodyViewDomainModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 04/07/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import CoreGraphics

struct BodyViewDomainModel: Decodable {
    let id: String
    let name: String
    let bodyParts: [BodyPartDomainModel]
}

struct BodyPartDomainModel: Decodable {
    let id: String
    let name: String
    let location: CGPoint
}
