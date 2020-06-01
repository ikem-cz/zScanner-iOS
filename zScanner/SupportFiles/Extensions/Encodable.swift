//
//  Encodable.swift
//  zScanner
//
//  Created by Jakub Skořepa on 06/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

extension Encodable {
    func toJSONData() -> Data? {
        return try? JSONEncoder().encode(self)
    }
    
    func properties() -> [(name: String, value: Any)] {
        let mirror = Mirror(reflecting: self)

        var properties = [(name: String, value: Any)]()
        for attribute in mirror.children {
            if let propertyName = attribute.label {
                let mirroredValue = Mirror(reflecting: attribute.value)
                if mirroredValue.displayStyle == Mirror.DisplayStyle.optional {
                    if let unwrapped = mirroredValue.children.first?.value {
                        let property = (name: propertyName, value: unwrapped)
                        properties.append(property)
                    }
                } else {
                    let property = (name: propertyName, value: attribute.value)
                    properties.append(property)
                }
            }
        }
        return properties
    }
}
