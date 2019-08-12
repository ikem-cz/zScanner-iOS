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
        case error(Error)
    }
    
    //MARK: Instance part
    private let database: Database
    private let networkManager: NetworkManager
    
    private(set) var documents: [DocumentViewModel] = []
    private(set) var documentModes: [DocumentMode] = []
    
    init(database: Database, ikemNetworkManager: NetworkManager) {
        self.database = database
        self.networkManager = ikemNetworkManager
        
        setupDocuments()
        fetchDocumentTypes()
    }
    
    //MARK: Interface
    let documentModesState = BehaviorSubject<DocumentModesState>(value: .awaitingInteraction)
    
    func insertNewDocument(_ document: DocumentViewModel) {
        documents.insert(document, at: 0)
    }
    func deleteHistory() {
        database.deleteAll(of: DocumentDatabaseModel.self)
        setupDocuments()
    }
    //MARK: Helpers
    let disposeBag = DisposeBag()
    
    private func setupDocuments() {
        documents = database
            .loadObjects(DocumentDatabaseModel.self)
            .map({ DocumentViewModel(document: $0.toDomainModel()) })
            .reversed()
    }
    
    private func fetchDocumentTypes() {
        networkManager.getDocumentTypes().subscribe(onNext: { [weak self] requestStatus in
            switch requestStatus {
            case .loading:
                self?.documentModesState.onNext(.loading)
                
            case .success(data: let networkModel):
                let documents = networkModel.map({ $0.toDomainModel() })
                
                self?.storeDocumentTypes(documents)
                self?.storeDocumentModes(from: documents)
                
                self?.documentModesState.onNext(.success)

            case .error(let error):
                self?.documentModesState.onNext(.error(error))
            }
        }).disposed(by: disposeBag)
    }
    
    private func storeDocumentModes(from documentTypes: [DocumentTypeDomainModel]) {
        documentModes = Array(Set(documentTypes.map({ $0.mode })))
        documentModes.append(.photo)
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
