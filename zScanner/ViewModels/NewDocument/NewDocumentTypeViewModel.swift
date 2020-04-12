//
//  NewDocumentTypeViewModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 04/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift

class NewDocumentTypeViewModel {
    
    // MARK: Instance part
    private let database: Database
    private let mode: DocumentMode
    
    init(documentMode: DocumentMode, database: Database) {
        self.database = database
        self.mode = documentMode
        self.fields = fields(for: mode)
        self.isValid = Observable
            .combineLatest(fields.map({ $0.isValid }))
            .map({ results in results.reduce(true, { $0 && $1 }) })
    }
    
    // MARK: Interface
    private(set) var fields: [FormField] = []
    
    var isValid = Observable<Bool>.just(false)
    
    func addDateTimePickerPlaceholder(at index: Int, for date: DateTimePickerField) {
        fields.insert(DateTimePickerPlaceholder(for: date), at: index)
    }
    
    func removeDateTimePickerPlaceholder() {
        fields.removeAll(where: { $0 is DateTimePickerPlaceholder })
    }
    
    // MARK: Helpers
    private func fields(for mode: DocumentMode) -> [FormField] {
        var documentTypes: [DocumentTypeDomainModel] {
            return database.loadObjects(DocumentTypeDatabaseModel.self)
                .map({ $0.toDomainModel() })
                .filter({ $0.mode == mode })
                .sorted(by: { $0.name < $1.name })
        }
        
        switch mode {
        case .document, .examination, .ext:
            return [
                ListPickerField<DocumentTypeDomainModel>(title: "form.listPicker.title".localized, list: documentTypes),
                TextInputField(title: "form.documentDecription.title".localized, validator: { _ in true }),
                DateTimePickerField(title: "form.dateTimePicker.title".localized, validator: { $0 != nil }),
            ]
        case .photo, .video, .undefined:
            return []
        }
    }
}
