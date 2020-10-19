//
//  BodyDefectDomainModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 05/07/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

struct BodyDefectDomainModel: ListItem {
    let id: String
    let title: String
    let bodyPartId: String
    private(set) var isNew = false
}

extension BodyDefectDomainModel {
    init(title: String, bodyPartId: String) {
        self.id = UUID().uuidString
        self.title = title
        self.bodyPartId = bodyPartId
        self.isNew = true
    }
}
