//
//  LoginCoordinator.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol LoginFlowDelegate: FlowDelegate {
    func successfulLogin()
}

class LoginCoordinator: Coordinator {
    
    // MARK: - Instance part
    unowned private let flowDelegate: LoginFlowDelegate
    
    init(flowDelegate: LoginFlowDelegate, window: UIWindow) {
        self.flowDelegate = flowDelegate
        
        super.init(window: window)
    }
    
    //MARK: Interface
    func begin() {
        showLogin()
    }
    
    // MARK: Navigation methods
    private func showLogin() {
        let viewController = LoginViewController(viewModel:
            LoginViewModel(model:
                LoginDomainModel(
                    username: "",
                    password: ""
                )
            ),
            coordinator: self
        )
        push(viewController)
    }
    
}

//MARK: - LoginViewDelegate implementation
extension LoginCoordinator: LoginViewDelegate {
    func successfulLogin() {
        flowDelegate.successfulLogin()
    }
}
