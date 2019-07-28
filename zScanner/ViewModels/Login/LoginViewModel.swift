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
    
    enum State {
        case loading
        case success
        case error(message: String)
        case awaitingInteraction
    }
 
    //MARK: Instance part
    var model: LoginDomainModel
    private let disposeBag = DisposeBag()
    
    let usernameField = UsernameViewModel()
    let passwordField = PasswordViewModel()
    
    let status = BehaviorRelay<State>(value: .awaitingInteraction)
    
    var isValid: Observable<Bool>
    
    init(model: LoginDomainModel) {
        self.model = model
        isValid = Observable<Bool>.combineLatest(usernameField.isValid, passwordField.isValid) { (username, password) -> Bool in
            return username && password
        }
    }
    
    //MARK: Interface
    func signin() {
        // update model
        model.username = usernameField.value.value
        model.password = passwordField.value.value
        
        status.accept(.success)
    
        print(model)
        // TODO: Continue with SeaCat
    }
}
