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
    
    var position: Int {
        switch id {
            case "FRONT": return 0
            case "BACK": return 1
            case "HEAD": return 2
            default: return 100
        }
    }
}

struct BodyPartDomainModel: Decodable {
    let id: String
    let name: String
    let location: CGPoint
}
