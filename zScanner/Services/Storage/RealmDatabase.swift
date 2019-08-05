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
extension Realm: Database {
    
    func loadObjects<T>(_ type: T.Type, predicate: NSPredicate?, sorted: Sorted?) -> [T] where T: Storable {
        var objects = self.objects(type as! Object.Type)
        
        if let predicate = predicate {
            objects = objects.filter(predicate)
        }
        
        if let sorted = sorted {
            objects = objects.sorted(byKeyPath: sorted.key, ascending: sorted.ascending)
        }
        
        return Array(objects) as! [T]
    }
    
    func loadObject<T: Storable>(_ type: T.Type, withId id: String) -> T? {
        return self.object(ofType: type as! Object.Type, forPrimaryKey: id) as! T?
    }
    
    func saveObject<T>(_ object: T) where T: Storable {
        try! self.write {
            self.add(object as! Object)
        }
    }
    
    func deleteAll<T>(of type: T.Type) where T: Storable {
        try! self.write {
            let objects = self.objects(type as! Object.Type)
            
            for object in objects {
                self.delete(object)
            }
        }
    }
}
