//
//  DocumentModesService.swift
//  zScanner
//
//  Created by Jakub Skořepa on 04/07/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

class DocumentModesFetchService: ViewControllerService {
    enum State {
        case awaitingInteraction
        case loading
        case success
        case error(RequestError)
    }
    
    private let database: Database
    private let networkManager: NetworkManager
    private let disposeBag = DisposeBag()
    private weak var controller: UIViewController?
    
    init(database: Database, networkManager: NetworkManager) {
        self.database = database
        self.networkManager = networkManager
    }
    
    let state = BehaviorSubject<State>(value: .awaitingInteraction)
    
    func viewDidLoad(_ controller: UIViewController) {
        self.controller = controller
        
        fetchDocumentTypes()
    }
    
    func fetchDocumentTypes() {
        networkManager
            .getDocumentTypes()
            .subscribe(onNext: { [weak self] requestStatus in
                switch requestStatus {
                case .progress:
                    self?.state.onNext(.loading)

                case .success(data: let networkModel):
                    let documents = networkModel.map({ $0.toDomainModel() })

                    self?.storeDocumentTypes(documents)
                    self?.state.onNext(.success)

                case .error(let error):
                    self?.state.onNext(.error(error))
                    self?.showDocumentTypesErrorAlert()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func storeDocumentTypes(_ types: [DocumentTypeDomainModel]) {
        DispatchQueue.main.async {
            self.database.deleteAll(of: DocumentTypeDatabaseModel.self)
            types
                .map({ DocumentTypeDatabaseModel(documentType: $0) })
                .forEach({ self.database.saveObject($0) })
        }
    }
    
    func showDocumentTypesErrorAlert() {
        let alert = UIAlertController(title: "dialog.requestError.title".localized, message: "dialog.requestError.noDocumentTypes".localized, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "dialog.requestError.retry".localized, style: .default, handler: { [weak self] _ in self?.fetchDocumentTypes() }))
        
        controller?.present(alert, animated: true)
    }
}
