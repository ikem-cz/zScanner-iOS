//
//  BodyPartsFetchService.swift
//  zScanner
//
//  Created by Jakub Skořepa on 04/07/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

class BodyPartsFetchService: ViewControllerService {
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
        
        fetchBodyParts()
    }
    
    func fetchBodyParts() {
        networkManager
            .getBodyParts()
            .subscribe(onNext: { [weak self] requestStatus in
                switch requestStatus {
                case .progress:
                    self?.state.onNext(.loading)

                case .success(data: let networkModel):
                    let bodyParts = networkModel.map({ $0.toDomainModel() })

                    self?.storeBodyParts(bodyParts)
                    self?.state.onNext(.success)

                case .error(let error):
                    self?.state.onNext(.error(error))
                    self?.showBodyPartsErrorAlert()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func storeBodyParts(_ bodyParts: [BodyViewDomainModel]) {
        DispatchQueue.main.async {
            self.database.deleteAll(of: BodyViewDatabaseModel.self)
            self.database.deleteAll(of: BodyPartDatabaseModel.self)
            bodyParts
                .map({ BodyViewDatabaseModel(bodyView: $0) })
                .forEach({ self.database.saveObject($0) })
        }
    }
    
    func showBodyPartsErrorAlert() {
        let alert = UIAlertController(title: "dialog.requestError.title".localized, message: "dialog.requestError.noBodyParts".localized, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "dialog.requestError.retry".localized, style: .default, handler: { [weak self] _ in self?.fetchBodyParts() }))
        
        controller?.present(alert, animated: true)
    }
}
