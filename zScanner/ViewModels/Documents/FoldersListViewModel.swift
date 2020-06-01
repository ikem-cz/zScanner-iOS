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

class FoldersListViewModel {
    enum DocumentModesState {
        case awaitingInteraction
        case loading
        case success
        case error(RequestError)
    }
    
    //MARK: Instance part
    private let database: Database
    private let networkManager: NetworkManager
    let login: LoginDomainModel
    
    private(set) var folders: [FolderViewModel] = []
    private(set) var activeFolders = BehaviorRelay<[FolderViewModel]>(value: [])
    private(set) var sentFolders = BehaviorRelay<[FolderViewModel]>(value: [])
    
    private(set) var documentModes: [DocumentMode] = []
    
    init(database: Database, login: LoginDomainModel, ikemNetworkManager: NetworkManager) {
        self.database = database
        self.login = login
        self.networkManager = ikemNetworkManager
        
        updateFolders()
        setupBindings()
        fetchDocumentTypes()
    }
    
    //MARK: Interface
    let documentModesState = BehaviorSubject<DocumentModesState>(value: .awaitingInteraction)
    
    func insertNewDocument(_ documentViewModel: DocumentViewModel) {
        if let folder = activeFolders.value.first(where: { return $0.folder.id == documentViewModel.document.folderId }) {
            folder.insertNewDocument(documentViewModel)
        } else if let folder = sentFolders.value.first(where: { return $0.folder.id == documentViewModel.document.folderId }) {
            folder.insertNewDocument(documentViewModel)
        } else {
            let databaseFolder = database.loadObject(FolderDatabaseModel.self, withId: documentViewModel.document.folderId)!
            let folder = FolderViewModel(folder: databaseFolder.toDomainModel(), documents: [documentViewModel])
            folders.insert(folder, at: 0)
            activeFolders.accept(folders.filter({ $0.folderStatus.value != .success }))
        }
    }
    
    private func setupBindings() {
        activeFolders
            .subscribe(onNext: { foldersViewModel in
                foldersViewModel.forEach { folderViewModel in
                    self.createFolderStatusSubscription(folderViewModel: folderViewModel)
                }
            })
            .disposed(by: disposeBag)
        
        sentFolders
            .subscribe(onNext: { foldersViewModel in
                foldersViewModel.forEach { folderViewModel in
                    self.createFolderStatusSubscription(folderViewModel: folderViewModel)
                }
            })
            .disposed(by: disposeBag)
    }
    
    func updateFolders() {
        loadFolders()
        
        // Filter folders by status
        activeFolders.accept(folders.filter({ $0.folderStatus.value != .success }))
        sentFolders.accept(folders.filter({ $0.folderStatus.value == .success }))
    }
    
    //MARK: Helpers
    let disposeBag = DisposeBag()
    
    private func loadFolders() {
        folders = database
            .loadObjects(FolderDatabaseModel.self)
            .sorted(by: { $0.lastUsed > $1.lastUsed })
            .map({ FolderViewModel(folder: $0.toDomainModel(), documents: documents(for: $0.id)) })
    }
    
    private func documents(for folderId: String) -> [DocumentViewModel] {
        let existingDocuments = folders.first(where: { $0.folder.id == folderId })?.documents.value ?? []
            
        let activeUploadDocuments = existingDocuments.filter({
            var currentStatus: DocumentViewModel.UploadStatus?
            $0.documentUploadStatus.subscribe(onNext: { status in currentStatus = status }).disposed(by: disposeBag)
            return currentStatus == .awaitingInteraction || currentStatus == .progress(0) // Any progress, parameter is not considered when comparing
        })
        
        var newDocuments = database
            .loadObjects(DocumentDatabaseModel.self)
            .filter({ $0.folder?.id == folderId })
            .map({ DocumentViewModel(document: $0.toDomainModel(), networkManager: networkManager, database: database) })
        
        // Replace all dummy* documents with active upload to show the process in UI.
        // *dummy document is document loaded from DB without active upload process
        for activeDocument in activeUploadDocuments {
            let _ = newDocuments.remove(activeDocument)
            newDocuments.insert(activeDocument, at: 0)
        }
        
        return newDocuments
    }
    
    private func createFolderStatusSubscription(folderViewModel: FolderViewModel) {
        folderViewModel.folderStatus
            .skip(1)
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] status in
                    self?.updateFolders()
            })
            .disposed(by: disposeBag)
    }
    
    func fetchDocumentTypes() {
        networkManager
            .getDocumentTypes()
            .subscribe(onNext: { [weak self] requestStatus in
                switch requestStatus {
                case .progress:
                    self?.documentModesState.onNext(.loading)

                case .success(data: let networkModel):
                    let documents = networkModel.map({ $0.toDomainModel() })

                    self?.storeDocumentTypes(documents)
                    self?.storeDocumentModes(from: documents)

                    self?.documentModesState.onNext(.success)

                case .error(let error):
                    self?.documentModesState.onNext(.error(error))
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func storeDocumentModes(from documentTypes: [DocumentTypeDomainModel]) {
        documentModes = Array(Set(documentTypes.map({ $0.mode })))
        documentModes.append(.photo)
        documentModes.append(.video)
    }
    
    private func storeDocumentTypes(_ types: [DocumentTypeDomainModel]) {
        DispatchQueue.main.async {
            self.database.deleteAll(of: DocumentTypeDatabaseModel.self)
            types
                .map({ DocumentTypeDatabaseModel(documentType: $0) })
                .forEach({ self.database.saveObject($0) })
        }
    }
}
