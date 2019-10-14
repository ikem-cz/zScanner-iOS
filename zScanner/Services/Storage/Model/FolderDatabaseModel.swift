//
//  FolderDatabaseModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 11/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RealmSwift

class FolderDatabaseModel: Object {
    @objc dynamic var externalId = ""
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    @objc dynamic var lastUsed = Date()
    
    convenience init(folder: FolderDomainModel) {
        self.init()
        
        self.id = folder.id
        self.externalId = folder.externalId
        self.name = folder.name
        self.lastUsed = Date()
    }
    
    override class func primaryKey() -> String {
        return "id"
    }
    
    static func updateLastUsage(of folder: FolderDatabaseModel) {
        let realm = try! Realm()
        if let stored = realm.object(ofType: FolderDatabaseModel.self, forPrimaryKey: folder.id) {
            try! realm.write {
                stored.lastUsed = Date()
            }
        } else {
            try! realm.write {
                realm.add(folder)
            }
        }
    }
}

extension FolderDatabaseModel {
    func toDomainModel() -> FolderDomainModel {
        return FolderDomainModel(
            externalId: externalId,
            id: id,
            name: name
        )
    }
}
