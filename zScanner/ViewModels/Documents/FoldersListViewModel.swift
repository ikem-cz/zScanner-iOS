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
//    private(set) var documentModes: [DocumentMode] = []
    
    init(database: Database, login: LoginDomainModel, ikemNetworkManager: NetworkManager) {
        self.database = database
        self.login = login
        self.networkManager = ikemNetworkManager
        
        loadFolders()
//        fetchDocumentTypes()
        setupBindings()
    }
    
    //MARK: Interface
    let documentModesState = BehaviorSubject<DocumentModesState>(value: .awaitingInteraction)
    
    func insertNewDocument(_ documentViewModel: DocumentViewModel) {
        updateFolders()
        
        if let folder = activeFolders.value.first(where: { return $0.folder.id == documentViewModel.document.folderId }) {
            folder.insertNewDocument(documentViewModel)
        }
        
        if let folder = sentFolders.value.first(where: { return $0.folder.id == documentViewModel.document.folderId }) {
            folder.insertNewDocument(documentViewModel)
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
    }
    
    func updateDocumentTypes() {
//        fetchDocumentTypes()
    }
    
    func updateFolders() {
        loadFolders()
        
        // Filter folders by status
        activeFolders.accept(folders.filter({
                var status: DocumentViewModel.UploadStatus?
                $0.folderStatus?.subscribe(onNext: { stat in status = stat }).disposed(by: disposeBag)
                return status! != .success
            })
        )

        sentFolders.accept(folders.filter({
                var status: DocumentViewModel.UploadStatus?
                $0.folderStatus?.subscribe(onNext: { stat in status = stat }).disposed(by: disposeBag)
                return status! == .success
            })
        )
    }
    
    //MARK: Helpers
    let disposeBag = DisposeBag()
    
    private func loadFolders() {
        folders = database
                 .loadObjects(FolderDatabaseModel.self)
                 .map({ FolderViewModel(folder: $0.toDomainModel(), networkManager: networkManager, database: database) })
                 .reversed()
    }
    
    private func createFolderStatusSubscription(folderViewModel: FolderViewModel) {
        folderViewModel.folderStatus?
            .subscribe(onNext: { status in
                if status == .success {
                    var newActiveFolders = self.activeFolders.value
                    _ = newActiveFolders.remove(folderViewModel)
                    self.activeFolders.accept(newActiveFolders)
                    
                    var newSentFolders = self.sentFolders.value
                    newSentFolders.append(folderViewModel)
                    self.sentFolders.accept(newSentFolders)
                } else {
                    var newSentFolders = self.sentFolders.value
                    _ = newSentFolders.remove(folderViewModel)
                    self.sentFolders.accept(newSentFolders)
                    
                    var newActiveFolders = self.activeFolders.value
                    newActiveFolders.append(folderViewModel)
                    self.activeFolders.accept(newActiveFolders)
                }
            })
            .disposed(by: self.disposeBag)
    }
    
//    func fetchDocumentTypes() {
//        networkManager
//            .getDocumentTypes()
//            .subscribe(onNext: { [weak self] requestStatus in
//                switch requestStatus {
//                case .progress:
//                    self?.documentModesState.onNext(.loading)
//
//                case .success(data: let networkModel):
//                    let documents = networkModel.map({ $0.toDomainModel() })
//
//                    self?.storeDocumentTypes(documents)
//                    self?.storeDocumentModes(from: documents)
//
//                    self?.documentModesState.onNext(.success)
//
//                case .error(let error):
//                    self?.documentModesState.onNext(.error(error))
//                }
//            })
//            .disposed(by: disposeBag)
//    }
    
//    private func storeDocumentModes(from documentTypes: [DocumentTypeDomainModel]) {
//        documentModes = Array(Set(documentTypes.map({ $0.mode })))
//        documentModes.append(.photo)
//        documentModes.append(.video)
//    }
    
//    private func storeDocumentTypes(_ types: [DocumentTypeDomainModel]) {
//        DispatchQueue.main.async {
//            self.database.deleteAll(of: DocumentTypeDatabaseModel.self)
//            types
//                .map({ DocumentTypeDatabaseModel(documentType: $0) })
//                .forEach({ self.database.saveObject($0) })
//        }
//    }
}
