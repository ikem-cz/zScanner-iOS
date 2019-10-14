//
//  RealmDatabase.swift
//  zScanner
//
//  Created by Jakub Skořepa on 26/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RealmSwift

// MARK:  Conformance to Storable protocol
extension Object: Storable {}

// MARK: -

typealias RealmDatabase = Realm

extension Realm: Database {
    
    func loadObjects<T>(_ type: T.Type) -> [T] where T: Storable {
        let objects = self.objects(type as! Object.Type)
        return Array(objects) as! [T]
    }
    
    func loadObject<T: Storable>(_ type: T.Type, withId id: String) -> T? {
        return self.object(ofType: type as! Object.Type, forPrimaryKey: id) as! T?
    }
    
    func saveObject<T: Storable>(_ object: T) {
        
        let update: UpdatePolicy = T.primaryKey() != nil ? .modified : .error
        
        try! self.write {
            self.add(object as! Object, update: update)
        }
    }
    
    func deleteObject<T: Storable>(_ object: T) {
        if let object = object as? RichDeleting {
            object.deleteRichContent()
        }
        
        try! self.write {
            self.delete(object as! Object)
        }
    }
}
