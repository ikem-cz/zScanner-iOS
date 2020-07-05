//
//  BodyDefectNetworkModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 05/07/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

struct BodyDefectNetworkModel: Decodable {
    let id: String
    let name: String
    let bodyPartId: String
}

extension BodyDefectNetworkModel {
    func toDomainModel() -> BodyDefectDomainModel {
        BodyDefectDomainModel(
            id: id,
            title: name,
            bodyPartId: bodyPartId
        )
    }
}
