//
//  LoginViewModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 20/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import SeaCatClient

class LoginViewModel {
    
    enum State: Equatable {
        case loading
        case success
        case error(message: String)
        case awaitingInteraction
    }
 
    //MARK: Instance part
    private let networkManager: NetworkManager
    var model: LoginDomainModel
    
    let usernameField = TextInputField(title: "login.username.title".localized, validator: { !$0.isEmpty })
    let passwordField = ProtectedTextInputField(title: "login.password.title".localized, validator: { !$0.isEmpty })
    
    let status = BehaviorSubject<State>(value: .awaitingInteraction)
    
    var isValid: Observable<Bool>
    
    init(model: LoginDomainModel, networkManager: NetworkManager) {
        self.networkManager = networkManager
        self.model = model
        isValid = Observable<Bool>.combineLatest(usernameField.isValid, passwordField.isValid) { (username, password) -> Bool in
            return username && password
        }
    }
    
    //MARK: Interface
    func signin() {
        guard let value = try? self.status.value(), value == .awaitingInteraction else {
            return
        }
        
        status.onNext(.loading)
        
        model.username = usernameField.text.value
        model.password = passwordField.text.value
        
        let seaCatToken = UUID().uuidString
        
        print("UUID: \(seaCatToken)")
        
        guard let csr = SCCSR() else {
            assertionFailure()
            return
        }
        csr.setGivenName(model.username)
        csr.setUniqueIdentifier(seaCatToken)
        let result = csr.submit(nil)
        print("CSR submit result: \(result)")
        
        networkManager.submitPassword(AuthNetworkModel(password: model.password, token: seaCatToken))
            .subscribe(onNext: { status in
                print(status)
            })
            .disposed(by: disposeBag)

        
        SeaCatClient.addObserver(self, selector:#selector(self.onStateChanged), name:SeaCat_Notification_StateChanged);
        seaCatTimer = Timer.scheduledTimer(timeInterval:1.0, target:self, selector:#selector(self.onStateChanged), userInfo:nil, repeats:true);
        onStateChanged()
    }
    
    // MAKR: Helpers
    private let disposeBag = DisposeBag()
    private var seaCatTimer: Timer!
    
    @objc func onStateChanged() {
        DispatchQueue.main.async {
            if SeaCatClient.isReady() {
                self.seaCatTimer.invalidate()
                SeaCatClient.removeObserver(self, name: SeaCat_Notification_StateChanged)
                self.status.onNext(.success)
                self.status.onCompleted()
            }
        }
    }
}
