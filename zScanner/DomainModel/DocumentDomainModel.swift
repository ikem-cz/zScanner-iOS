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
    var date: Date
    var name: String
    var notes: String
    var pages: [Media]
}

extension DocumentDomainModel: Hashable {
    static func == (lhs: DocumentDomainModel, rhs: DocumentDomainModel) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension DocumentDomainModel {
    static var emptyDocument: DocumentDomainModel {
        return DocumentDomainModel(
            id: UUID().uuidString,
            folderId: "",
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
