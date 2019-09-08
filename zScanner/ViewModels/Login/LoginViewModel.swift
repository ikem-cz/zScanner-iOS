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

class LoginViewModel {
    
    enum State: Equatable {
        case loading
        case success
        case error(RequestError)
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
        guard (try? self.status.value()) == .awaitingInteraction else { return }
        
        status.onNext(.loading)
        
        model.username = usernameField.text.value
        model.password = passwordField.text.value
        
        seaCatToken = UUID().uuidString
        
        startSeaCatLogin()
    }
    
    // MAKR: Helpers
    private var disposeBag = DisposeBag()
    private var seaCatTimer: Timer?
    private var timeoutTimer: Timer?
    private var seaCatToken: String?
    
    private func startSeaCatLogin() {
        guard let csr = SCCSR() else {
            assertionFailure()
            return
        }
        
        guard let token = seaCatToken else { return }
        
        csr.setGivenName(model.username)
        csr.setUniqueIdentifier(token)
        csr.submit(nil)
        
        networkManager.submitPassword(AuthNetworkModel(password: model.password, token: token))
            .subscribe(onNext: { [weak self] status in
                switch status {
                case .progress:
                    break
                case .success:
                    self?.startCheckingSeaCatStatus()
                case .error(let error):
                    self?.error(error)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func startCheckingSeaCatStatus() {
        SeaCatClient.addObserver(self, selector: #selector(onStateChanged), name: SeaCat_Notification_StateChanged)
        seaCatTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.onStateChanged), userInfo: nil, repeats: true)
        onStateChanged()
        
        timeoutTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(timeout), userInfo: nil, repeats: false)
    }
    
    private var statusCheckRunning = false
    
    private func checkSeaCatStatus() {
        guard let token = seaCatToken, !statusCheckRunning else { return }
       
        statusCheckRunning = true
        
        networkManager.getStatus(TokenNetworkModel(token: token))
            .subscribe(onNext: { [weak self] status in
                switch status {
                case .success(data: let data):
                    let state = data.status
                    if state.cert {
                        self?.success()
                    } else if !(state.cert || state.username || state.password) {
                        self?.error(RequestError(.logicError, message: "login.failed.message".localized))
                    }
                default:
                    break
                }
            }, onError: { [weak self] _ in
                self?.statusCheckRunning = false
            }, onCompleted: { [weak self] in
                self?.statusCheckRunning = false
            })
            .disposed(by: disposeBag)
    }
    
    @objc private func onStateChanged() {
        DispatchQueue.main.async {
            if SeaCatClient.isReady() {
                self.success()
            }
        }
        checkSeaCatStatus()
    }
    
    @objc private func timeout() {
        error(RequestError(.timeout))
    }
    
    private func cleanUp() {
        seaCatTimer?.invalidate()
        timeoutTimer?.invalidate()
        SeaCatClient.removeObserver(self, name: SeaCat_Notification_StateChanged)
        disposeBag = DisposeBag()
    }
    
    private func success() {
        guard (try? status.value()) == .loading else { return }
        
        cleanUp()
        
        status.onNext(.success)
        status.onCompleted()
    }
    
    private func error(_ error: RequestError) {
        guard (try? status.value()) == .loading else { return }
        
        cleanUp()
        
        SeaCatClient.reset()
        status.onNext(.error(error))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.status.onNext(.awaitingInteraction)
        }
    }
}
