//
//  DocumentDomainModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 21/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

struct DocumentDomainModel {
    var id: String
    var folder: FolderDomainModel
    var type: DocumentTypeDomainModel
    var date: Date
    var name: String
    var notes: String
    var pages: [UIImage]
}

extension DocumentDomainModel {
    static var emptyDocument: DocumentDomainModel {
        return DocumentDomainModel(
            id: UUID().uuidString,
            folder: FolderDomainModel(
                externalId: "",
                id: "",
                name: ""
            ),
            type: DocumentTypeDomainModel(
                id: "",
                name: "",
                mode: .undefined
            ),
            date: Date(),
            name: "",
            notes: "",
            pages: []
        )
    }
}
