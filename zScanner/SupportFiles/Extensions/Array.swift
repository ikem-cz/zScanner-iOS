//
//  Array.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

// MARK: Equatable implementation
extension Array where Element: Equatable {
    /**
     Remove first collection element that is equal to the given `object`
     - Parameter object: Object to remove
     Source: http://stackoverflow.com/questions/24938948/array-extension-to-remove-object-by-value
     */
    mutating func remove(_ object: Element) -> Element? {
        if let index = firstIndex(of: object) {
            return remove(at: index)
        }
        return nil
    }
}

extension Array {
    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        return sorted { a, b in
            return a[keyPath: keyPath] < b[keyPath: keyPath]
        }
    }
}
