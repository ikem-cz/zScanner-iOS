//
//  DocumentType.swift
//  zScanner
//
//  Created by Jakub Skořepa on 28/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

struct DocumentTypeNetworkModel: Decodable {
    var mode: String
    var display: String
    var type: String
}

extension DocumentTypeNetworkModel {
    func toDomainModel() -> DocumentTypeDomainModel {
        return DocumentTypeDomainModel(
            id: type,
            name: display,
            mode: DocumentMode(rawValue: mode) ?? .undefined
        )
    }
}
