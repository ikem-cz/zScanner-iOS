//
//  FolderNetworkModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 10/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

struct FolderNetworkModel: Decodable {
    var externalId : String
    var internalId : String
    var name: String
}

extension FolderNetworkModel {
    func toDomainModel() -> FolderDomainModel {
        return FolderDomainModel(
            externalId: externalId,
            id: internalId,
            name: name
        )
    }
}
