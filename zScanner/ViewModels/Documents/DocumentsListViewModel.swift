//
//  DocumentsListViewModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 21/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

class DocumentsListViewModel {
    
    //MARK: Instance part
    private let database: Database
    private(set) var documents: [DocumentViewModel] = []
    private(set) var documentModes: [DocumentMode] = []
    
    init(database: Database) {
        self.database = database
        
        setupDocuments()
    }
    
    func reloadRocuments() {
       documents = database.loadObjects(DocumentDatabaseModel.self, predicate: nil, sorted: nil).map({ DocumentViewModel(document: $0.toDomainModel()) })
    }
    
    //MARK: Helpers
    private func setupDocuments() {
        reloadRocuments()
        
        documentModes = Array(Set(
            database.loadObjects(DocumentTypeDatabaseModel.self, predicate: nil, sorted: nil)
                .map({ $0.mode })
        ))
        documentModes.append(.photo)
    }
}
