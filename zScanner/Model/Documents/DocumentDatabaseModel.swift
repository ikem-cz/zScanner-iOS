//
//  DocumentRealmModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 24/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RealmSwift


class DocumentDatabaseModel: Object {
    @objc dynamic var id = ""
    @objc dynamic var folderId = ""
    @objc dynamic var documentMode = ""
    @objc dynamic var documentType = ""
    @objc dynamic var documentTypeName = ""
    @objc dynamic var date = Date()
    @objc dynamic var name = ""
    @objc dynamic var notes = ""
    let pages = List<String>()
    
    convenience init(document: DocumentDomainModel) {
        self.init()
        
        self.id = document.id
        self.folderId = document.folderId
        self.documentMode = document.type.mode.rawValue
        self.documentType = document.type.id
        self.documentTypeName = document.type.name
        self.date = document.date
        self.name = document.name
        self.notes = document.notes
        
        // TODO: convert image into filePath
    }
    
    override class func primaryKey() -> String {
        return "id"
    }
}

//MARK: -
extension DocumentDatabaseModel {
    func toDomainModel() -> DocumentDomainModel {
        return DocumentDomainModel(
            id: id,
            folderId: folderId,
            type: DocumentTypeDomainModel(
                id: documentType,
                name: documentTypeName,
                mode: DocumentMode(rawValue: documentMode)!
            ),
            date: date,
            name: name,
            notes: notes,
            pages: []
        )
    }
}
