//
//  NewDocumentFolderViewModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 10/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

class NewDocumentFolderViewModel {
    
    // MARK: Instance part
    private let database: Database
    private let networkManager: NetworkManager
    private let tracker: Tracker
    
    init(database: Database, networkManager: NetworkManager, tracker: Tracker) {
        self.database = database
        self.networkManager = networkManager
        self.tracker = tracker
    }
    
    // MARK: Interface
    let suggestedResults = BehaviorRelay<[FolderDomainModel]>(value: [])
    let searchResults = BehaviorRelay<[FolderDomainModel]>(value: [])
    let isLoading = BehaviorRelay<Bool>(value: false)
    private(set) var lastUsedSearchMode: SearchMode = .search
    
    func search(query: String) {
        if query.isEmpty {
            searchResults.accept([])
            suggestedResults.accept([])
            return
        }
        
        lastUsedSearchMode = .search
        activeSearch = networkManager.searchFolders(with: query)
    }
    
    func getFolder(with id: String) {
        lastUsedSearchMode = .scan
        searchResults.accept([])
        suggestedResults.accept([])
        let id = id.trimmingCharacters(in: CharacterSet.decimalDigits.inverted)
        activeSearch = networkManager.getFolder(with: id).map({ (result) -> RequestStatus<[FolderNetworkModel]> in
            switch result {
                case .progress(let percentage): return .progress(percentage)
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
                case .progress:
                    self?.isLoading.accept(true)
                case .success(data: let folders):
                    self?.isLoading.accept(false)
                    var folders = folders.map({ $0.toDomainModel() })
                    if folders.isEmpty {
                        self?.tracker.track(.userNotFound)
                        folders.append(.notFound)
                    }
                    self?.searchResults.accept(folders.filter({ $0.type != .suggested }))
                    self?.suggestedResults.accept(folders.filter({ $0.type == .suggested }))
                case .error:
                    self?.tracker.track(.userNotFound)
                    self?.isLoading.accept(false)
                    self?.searchResults.accept([.notFound])
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
