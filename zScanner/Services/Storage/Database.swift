//
//  Database.swift
//  zScanner
//
//  Created by Jakub Skořepa on 26/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

protocol Storable {}

// MARK: -
protocol Database {
    func loadObjects<T: Storable>(_ type: T.Type, predicate: NSPredicate?, sorted: Sorted?) -> [T]
    func loadObject<T: Storable>(_ type: T.Type, withId id: String) -> T?
    func saveObject<T: Storable>(_ object: T)
    func deleteAll<T: Storable>(of type: T.Type)
}

// MARK: - 
public struct Sorted {
    var key: String
    var ascending: Bool = true
}
