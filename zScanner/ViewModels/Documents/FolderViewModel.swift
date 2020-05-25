//
//  FolderViewModel.swift
//  zScanner
//
//  Created by Jan Provazník on 21/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay


class FolderViewModel {
    typealias UploadStatus = DocumentViewModel.UploadStatus

    // MARK: Instance part
    private var networkManager: NetworkManager
    private var database: Database
    var documents = BehaviorRelay<[DocumentViewModel]>(value: [])
    let folder: FolderDomainModel
    
    private lazy var statusToProgress: ([UploadStatus]) -> UploadStatus = { [weak self] tasks in
        var progresses = [Double]()
        var inProgressCount = 0
        var awaitingCount = 0
        var failed = false
        var error: RequestError?
        
        for status in tasks {
            switch status {
            case .awaitingInteraction:
                awaitingCount += 1
                progresses.append(0)
            case .progress(let percentage):
                inProgressCount += 1
                progresses.append(percentage * 0.9)
            case .success:
                progresses.append(1)
            case .failed(let e):
                failed = true
                error = e
                progresses.append(0)
            }
        }

        if inProgressCount == 0 && awaitingCount == 0 {
            if failed {
                return .failed(error)
            } else {
                return .success
            }
        }
        
        let overallProgress = progresses.reduce(0, { $0 + $1 }) / Double(progresses.count)
        return .progress(overallProgress)
    }
    
    var folderStatus: Observable<UploadStatus>?
    
    private var tasks: [Observable<UploadStatus>] {
        documents.value.map({ $0.documentUploadStatus.asObservable() })
    }
    
    init(folder: FolderDomainModel, networkManager: NetworkManager, database: Database) {
        self.folder = folder
        self.networkManager = networkManager
        self.database = database
        
        loadDocuments()
        setupBindings()
    }
    
    deinit {
        documentsSubscription?.dispose()
    }
    
    // MARK: Helpers
    private var documentsSubscription: Disposable?
    
    private func setupBindings() {
        documentsSubscription = documents.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            
            self.folderStatus = Observable
                .combineLatest(self.tasks)
                .map(self.statusToProgress)
                .asObservable()
        })
    }
    
    func insertNewDocument(_ document: DocumentViewModel) {
        var newArray = documents.value
        newArray.append(document)
        documents.accept(newArray)
    }
    
    func loadDocuments() {
        let newDocuments = folder.documents.map { DocumentViewModel(document: $0, networkManager: networkManager, database: database) }
        documents.accept(newDocuments)
    }
}

extension FolderViewModel: Hashable {
    static func == (lhs: FolderViewModel, rhs: FolderViewModel) -> Bool {
        return lhs.folder == rhs.folder
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(folder)
    }
}
