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
    
    private(set) var documents: [DocumentViewModel] = []
    private(set) var activeDocuments = BehaviorRelay<[DocumentViewModel]>(value: [])
    private(set) var sentDocuments = BehaviorRelay<[DocumentViewModel]>(value: [])
    private(set) var documentModes: [DocumentMode] = []
    
    init(database: Database, login: LoginDomainModel, ikemNetworkManager: NetworkManager) {
        self.database = database
        self.login = login
        self.networkManager = ikemNetworkManager
        
        loadDocuments()
        fetchDocumentTypes()
    }
    
    //MARK: Interface
    let documentModesState = BehaviorSubject<DocumentModesState>(value: .awaitingInteraction)
    
    func insertNewDocument(_ document: DocumentViewModel) {
        var newArray = activeDocuments.value
        newArray.insert(document, at: 0)
        activeDocuments.accept(newArray)
    }
    
    func updateDocumentTypes() {
        fetchDocumentTypes()
    }
    
    func setDocumentAsSent(_ document: DocumentViewModel) {
        var newArray = activeDocuments.value
        guard let _ = newArray.remove(document) else {
            print("Document could not be removed.")
            return
        }
        activeDocuments.accept(newArray)
        
        newArray = sentDocuments.value
        newArray.insert(document, at: 0) 
        sentDocuments.accept(newArray)
    }
    
    func updateDocuments() {
        // Find all documents with active upload
        let activeUploadDocuments = documents.filter({
            var currentStatus: DocumentViewModel.UploadStatus?
            $0.documentUploadStatus.subscribe(onNext: { status in currentStatus = status }).disposed(by: disposeBag)
            return currentStatus == .awaitingInteraction || currentStatus == .progress(0) // Any progress, parameter is not considered when comparing
        })
        
        loadDocuments()
        
        // Replace all dummy* documents with active upload to show the process in UI.
        // *dummy document is document loaded from DB without active upload process
        for activeDocument in activeUploadDocuments {
            let _ = documents.remove(activeDocument)
            documents.insert(activeDocument, at: 0)
        }
        
        // Filter documents by status
        activeDocuments.accept(documents.filter({
                var status: DocumentViewModel.UploadStatus?
                $0.documentUploadStatus.subscribe(onNext: { stat in status = stat }).disposed(by: disposeBag)
                return status! != .success
            })
        )
        
        sentDocuments.accept(documents.filter({
                var status: DocumentViewModel.UploadStatus?
                $0.documentUploadStatus.subscribe(onNext: { stat in status = stat }).disposed(by: disposeBag)
                return status! == .success
            })
        )
    }
    
    //MARK: Helpers
    let disposeBag = DisposeBag()
    
    private func loadDocuments() {
        documents = database
            .loadObjects(DocumentDatabaseModel.self)
            .map({ DocumentViewModel(document: $0.toDomainModel(), networkManager: networkManager, database: database) })
            .reversed()
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
