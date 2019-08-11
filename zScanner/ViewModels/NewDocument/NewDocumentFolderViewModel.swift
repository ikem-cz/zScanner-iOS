//
//  NewDocumentFolderViewModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 10/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift

class NewDocumentFolderViewModel {
    
    // MARK: - Instance part
    private let database: Database
    private let networkManager: NetworkManager
    
    init(database: Database, networkManager: NetworkManager) {
        self.database = database
        self.networkManager = networkManager
        
        history = database
            .loadObjects(FolderDatabaseModel.self)
            .sorted(by: { $0.lastUsed > $1.lastUsed })
            .prefix(Config.folderUsageHistoryCount)
            .map({ $0.toDomainModel() })
    }
    
    // MARK: Interface
    let history: [FolderDomainModel]
    let searchResults = BehaviorSubject<[FolderDomainModel]>(value: [])
    let isLoading = BehaviorSubject<Bool>(value: false)
    
    func search(query: String) {
        activeSearch = networkManager.searchFolders(with: query)
    }
    
    func getFolder(with id: String) {
        let id = id.trimmingCharacters(in: CharacterSet.decimalDigits.inverted)
        activeSearch = networkManager.getFolder(with: id).map({ (result) -> RequestStatus<[FolderNetworkModel]> in
            switch result {
                case .loading: return .loading
                case .success(data: let folder): return .success(data: [folder])
                case .error(let error): return .error(error)
            }
        })
    }
    
    // MARK: Helpers
    private let disposeBag = DisposeBag()
    private var activeSearch: Observable<RequestStatus<[FolderNetworkModel]>>? {
        didSet {
            activeSearchDisposable = activeSearch?.subscribe(onNext: { [weak self] status in
                switch status {
                case .loading:
                    self?.isLoading.onNext(true)
                case .success(data: let folders):
                    self?.isLoading.onNext(false)
                    let folders = folders.map({ $0.toDomainModel() })
                    self?.searchResults.onNext(folders)
                case .error(let error):
                    self?.isLoading.onNext(false)
                    self?.searchResults.onNext([])
                    
                    // TODO: Handle error
                    print(error)
                }
            })
        }
    }
    
    private var activeSearchDisposable: Disposable? {
        didSet {
            oldValue?.dispose()
            activeSearchDisposable?.disposed(by: disposeBag)
        }
    }
}
