//
//  LoginCoordinator.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol LoginFlowDelegate: FlowDelegate {
    func successfulLogin(userSession: UserSession)
}

class LoginCoordinator: Coordinator {
    
    // MARK: Instance part
    unowned private let flowDelegate: LoginFlowDelegate
    
    init(flowDelegate: LoginFlowDelegate, window: UIWindow) {
        self.flowDelegate = flowDelegate
        
        super.init(window: window)
    }
    
    //MARK: Interface
    func begin() {
        showLoginScreen()
    }
    
    // MARK: Navigation methods
    private func showLoginScreen() {
        let viewModel = LoginViewModel(networkManager: networkManager)
        let viewController = LoginViewController(viewModel: viewModel, coordinator: self)
        changeWindowControllerTo(viewController)
    }
    
    // MARK: Helpers
    private lazy var api: API = NativeAPI()
    private lazy var networkManager: NetworkManager = IkemNetworkManager(api: api)
}

//MARK: - LoginViewDelegate implementation
extension LoginCoordinator: LoginViewDelegate {
    func successfulLogin(with login: LoginDomainModel) {
        let userSession = UserSession(login: login)
        flowDelegate.successfulLogin(userSession: userSession)
        flowDelegate.coordinatorDidFinish(self)
    }
}
