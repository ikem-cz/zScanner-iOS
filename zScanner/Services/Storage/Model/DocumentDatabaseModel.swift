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
    @objc dynamic var documentMode = ""
    @objc dynamic var documentType = ""
    @objc dynamic var documentTypeName = ""
    @objc dynamic var date = Date()
    @objc dynamic var name = ""
    @objc dynamic var notes = ""
    @objc dynamic var folder: FolderDatabaseModel?
    let pages = List<PageDatabaseModel>()
    
    convenience init(document: DocumentDomainModel) {
        self.init()
        
        self.id = document.id
        self.documentMode = document.type.mode.rawValue
        self.documentType = document.type.id
        self.documentTypeName = document.type.name
        self.date = document.date
        self.name = document.name
        self.notes = document.notes
        
        let realm = try! Realm()
        self.folder = realm.loadObject(FolderDatabaseModel.self, withId: document.folder.id) ?? FolderDatabaseModel(folder: document.folder)
        
        self.pages.append(objectsIn: document.pages.map({ PageDatabaseModel(page: $0) }))
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
            folder: folder!.toDomainModel(),
            type: DocumentTypeDomainModel(
                id: documentType,
                name: documentTypeName,
                mode: DocumentMode(rawValue: documentMode)!
            ),
            date: date,
            name: name,
            notes: notes,
            pages: pages.map({ $0.toDomainModel() })
        )
    }
}

extension DocumentDatabaseModel: RichDeleting {
    func deleteRichContent() {
        let folderPath = URL.documentsPath + "/" + id
        try? FileManager.default.removeItem(atPath: folderPath)
    }
}
