//
//  NewDocumentTypeViewModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 04/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

class NewDocumentTypeViewModel {
    
    // MARK: - Instance part
    private let database: Database
    private let mode: DocumentMode
    
    init(documentMode: DocumentMode, database: Database) {
        self.database = database
        self.mode = documentMode
        self.fields = fields(for: mode)
    }
    
    // MARK: Interface
    private(set) var fields: [FormField] = []
    
    // MARK: Helpers
    private func fields(for mode: DocumentMode) -> [FormField] {
        
        var documentTypes: [DocumentTypeDomainModel] {
            return database.loadObjects(DocumentTypeDatabaseModel.self, predicate: nil, sorted: nil)
                .map({ $0.toDomainModel() })
                .filter({ $0.mode == mode })
                .sorted(by: { $0.name < $1.name })
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .long
        
        switch mode {
        case .document, .examination:
            return [
                ListPickerField<DocumentTypeDomainModel>(title: "form.listPicker.title".localized, list: documentTypes),
                TextInputField(title: "form.documentDecription.title".localized, validator: { !$0.isEmpty }),
                DateTimePickerField(title: "form.dateTimePicker.title".localized, formatter: dateFormatter, validator: { $0 != nil && $0! > Date() })
            ]
        case .photo, .undefined:
            return []
        }
    }
}
