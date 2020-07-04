//
//  BodyViewNetworkModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 04/07/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import CoreGraphics

struct BodyViewNetworkModel: Decodable {
    let id: String
    let bodyParts: [BodyPartNetworkModel]
}

extension BodyViewNetworkModel {
    func toDomainModel() -> BodyViewDomainModel {
        BodyViewDomainModel(
            id: id,
            bodyParts: bodyParts.map { $0.toDomainModel() }
        )
    }
}

struct BodyPartNetworkModel: Decodable {
    let id: String
    let name: String
    let coordinates: [Double]
}

extension BodyPartNetworkModel {
    func toDomainModel() -> BodyPartDomainModel {
        let x = Double(coordinates[0])
        let y = Double(coordinates[1])
        
        return BodyPartDomainModel(
            id: id,
            name: name,
            location: CGPoint(x: x, y: y)
        )
    }
}
