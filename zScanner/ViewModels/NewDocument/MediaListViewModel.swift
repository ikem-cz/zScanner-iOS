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

class MediaListViewModel {
    
    // MARK: Instance part
    private let tracker: Tracker
    private let database: Database
    
    let allDocumentTypes: [DocumentTypeDomainModel]
    let scanModes: BehaviorRelay<[DocumentMode]>
    private(set) var mediaType: MediaType
    let folderName: String
    let mediaArray = BehaviorRelay<[Media]>(value: [])
    let isValid = BehaviorRelay<Bool>(value: false)
    
    private(set) var fields: [[FormField]] = [[]]
    
    init(database: Database, folderName: String, mediaType: MediaType, tracker: Tracker) {
        self.tracker = tracker
        self.mediaType = mediaType
        self.folderName = folderName
        self.database = database
        
        self.allDocumentTypes = database.loadObjects(DocumentTypeDatabaseModel.self).map({ $0.toDomainModel() })
        self.scanModes = BehaviorRelay(value: Array(Set(allDocumentTypes.map({ $0.mode }))))
        
        updateMediaType(to: mediaType)
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
    
    func addDateTimePickerPlaceholder(index: Int, section: Int, for date: DateTimePickerField) {
        fields[section].insert(DateTimePickerPlaceholder(for: date), at: index)
    }
    
    func removeDateTimePickerPlaceholder(section: Int) {
        fields[section].removeAll(where: { $0 is DateTimePickerPlaceholder })
    }
    
    func updateMediaType(to newMediaType: MediaType) {
        mediaType = newMediaType
        fields = fields(for: mediaType)
        
        let sectionsResults = fields
            .map({ section in
                Observable
                    .combineLatest(section.map({ $0.isValid }))
                    .map({ results in results.reduce(true, { $0 && $1 }) })
            })
        
        subscription?.dispose()
        subscription = Observable
            .combineLatest(sectionsResults)
            .map({ results in results.reduce(true, { $0 && $1 }) })
            .subscribe(onNext: { [weak self] result in
                self?.isValid.accept(result)
            })
    }
    
    // MARK: Helpers
    private let disposeBag = DisposeBag()
    private var subscription: Disposable?
    
    private func fields(for type: MediaType) -> [[FormField]] {
        switch type {
        case .scan:
            return [
                [modePicker],
                [typePicker, titlePicker, timePicker],
                [collectionView]
            ]
            
        case .photo:
            return [
                [timePicker],
                [collectionView]
            ]
        
        case .video:
            return [
                [timePicker, titlePicker],
                [collectionView]
            ]
        }
    }
    
    private lazy var modePicker: SegmentPickerField<DocumentMode> = {
        let picker = SegmentPickerField(values: [DocumentMode.document, .examination])
        picker.selected
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] selectedMode in
                self?.typePicker.list = self?.allDocumentTypes
                    .filter({ $0.mode == selectedMode })
                    .sorted(by: { $0.name < $1.name })
                    ?? []
                self?.typePicker.selected.accept(nil)
            })
            .disposed(by: disposeBag)
        return picker
    }()
    private lazy var typePicker = ListPickerField<DocumentTypeDomainModel>(title: "form.listPicker.title".localized, list: [])
    private lazy var titlePicker = TextInputField(title: "form.documentDecription.title".localized, validator: { _ in true })
    private lazy var timePicker = DateTimePickerField(title: "form.dateTimePicker.title".localized, setDate: mediaType != .scan, validator: { $0 != nil })
    private lazy var collectionView = CollectionViewField()
}
