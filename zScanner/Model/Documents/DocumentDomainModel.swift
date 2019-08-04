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
    var folderId: String
    var type: DocumentTypeDomainModel
    var created: Date
    var name: String
    var notes: String
    var pages: [UIImage]
}

extension DocumentDomainModel {
    static var emptyDocument: DocumentDomainModel {
        return DocumentDomainModel(
            id: "",
            folderId: "",
            type: DocumentTypeDomainModel(
                id: "",
                name: "",
                mode: .undefined
            ),
            created: Date(),
            name: "",
            notes: "",
            pages: []
        )
    }
}
