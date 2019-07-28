//
//  DocumentViewModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 21/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

class DocumentViewModel {
    let document: DocumentDomainModel
    
    init(document: DocumentDomainModel) {
        self.document = document
    }
}
