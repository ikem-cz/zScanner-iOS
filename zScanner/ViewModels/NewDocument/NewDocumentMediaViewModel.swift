//
//  NewDocumentMediaViewModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 14/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay
import AVFoundation

class NewDocumentMediaViewModel {
    
    // MARK: Instance part
    private let tracker: Tracker
    private let database: Database
    private let mode: DocumentMode
    let mediaType: MediaType
    let folderName: String
    let mediaArray = BehaviorRelay<[Media]>(value: [])
    
    init(documentMode: DocumentMode, database: Database, folderName: String, mediaType: MediaType, tracker: Tracker) {
        self.tracker = tracker
        self.mediaType = mediaType
        self.folderName = folderName
        self.database = database
        self.mode = documentMode
        self.fields = fields(for: mode)
        self.isValid = Observable
            .combineLatest(fields.map({ $0.isValid }))
            .map({ results in results.reduce(true, { $0 && $1 }) })
    }
    
    // MARK: Interface
    func addMedia(_ media: Media) {
        // Checking for adding media multiple times after reedit
        guard mediaArray.value.firstIndex(of: media) == nil else { return }
        
        // Tracking
        tracker.track(.galleryUsed(media.fromGallery))
        
        // Add media
        var newArray = mediaArray.value
        newArray.append(media)
        mediaArray.accept(newArray)
    }
    
    func removeMedia(_ media: Media) {
        // Tracking
        tracker.track(.deleteImage)

        // Remove media
        var newArray = mediaArray.value
        _ = newArray.remove(media)
        mediaArray.accept(newArray)
    }
    
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
//        var documentTypes: [DocumentTypeDomainModel] {
//            return database.loadObjects(DocumentTypeDatabaseModel.self)
//                .map({ $0.toDomainModel() })
//                .filter({ $0.mode == mode })
//                .sorted(by: { $0.name < $1.name })
//        }
//
//        switch mode {
//        case .document, .examination, .ext:
            return [
                SegmentControlField(),
//                ListPickerField<DocumentTypeDomainModel>(title: "form.listPicker.title".localized, list: documentTypes),
                TextInputField(title: "form.documentDecription.title".localized, validator: { _ in true }),
                DateTimePickerField(title: "form.dateTimePicker.title".localized, validator: { $0 != nil }),
            ]
//        case .photo, .video, .undefined:
//            return []
//        }
    }
}
