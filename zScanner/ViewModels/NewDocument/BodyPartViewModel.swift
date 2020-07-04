//
//  BodyPartViewModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 04/07/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

class BodyPartViewModel {
    enum State {
        case awaitingInteraction
        case loading
        case success(UIImage)
        case error(RequestError)
    }
    
    // MARK: Instance part
    private let database: Database
    private let networkManager: NetworkManager
    private(set) var bodyViews: [BodyViewDomainModel] = []
    var bodyImage = BehaviorRelay<State>(value: .awaitingInteraction)
    
    init(database: Database, networkManager: NetworkManager) {
        self.database = database
        self.networkManager = networkManager
        self.bodyViews = database.loadObjects(BodyViewDatabaseModel.self)
            .map({ $0.toDomainModel() })
        
        bodyViews.first.flatMap { getImage(for: $0) }
    }
    
    func getImage(for view: BodyViewDomainModel) {
        networkManager
            .getBodyImage(id: view.id)
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .progress:
                    self?.bodyImage.accept(.loading)
                case .success(data: let networkModel):
                    self?.bodyImage.accept(.success(networkModel.image))
                case .error(let error):
                    self?.bodyImage.accept(.error(error))
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: Helpers
    private var disposeBag = DisposeBag()
}
