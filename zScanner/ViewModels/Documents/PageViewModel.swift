//
//  PageViewModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 08/09/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift

class PageViewModel {
    
    // MARK: Instance part
    private var networkManager: NetworkManager
    private var database: Database
    let page: PageDomainModel
    let pageUploadStatus = BehaviorSubject<DocumentViewModel.UploadStatus>(value: .awaitingInteraction)
    
    
    init(page: PageDomainModel, networkManager: NetworkManager, database: Database) {
        self.page = page
        
        self.networkManager = networkManager
        self.database = database
        
        if let databaseModel = database.loadObjects(PageUploadStatusDatabaseModel.self).filter({ $0.correlationId == page.correlationId && $0.index == page.index }).first {
            pageUploadStatus.onNext(databaseModel.uploadStatus == .success ? .success : .failed)
        }
    }
    
    // MARK: Interface
    func uploadPage() {
        pageUploadStatus.onNext(.progress(0))
        setupBindings()
        
        let pageNetworkModel = PageNetworkModel(from: page)
        
        networkManager
            .uploadPage(pageNetworkModel)
            .subscribe(onNext: { [weak self] requestStatus in
                switch requestStatus {
                case .progress(let percentage):
                    self?.pageUploadStatus.onNext(.progress(percentage))
                case .success:
                    self?.pageUploadStatus.onNext(.progress(1))
                    self?.pageUploadStatus.onNext(.success)
                case .error:
                    self?.pageUploadStatus.onNext(.failed)
                }
            }, onError: { [weak self] error in
                self?.pageUploadStatus.onError(error)
            }, onCompleted: { [weak self] in
                self?.pageUploadStatus.onCompleted()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: Helpers
    private let disposeBag = DisposeBag()
    
    private func setupBindings() {
        pageUploadStatus
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self]  status in
                guard let `self` = self else { return }
                let pageUploadStatus = PageUploadStatusDatabaseModel(viewModel: self)
                self.database.saveObject(pageUploadStatus)
            })
            .disposed(by: disposeBag)
    }
}
