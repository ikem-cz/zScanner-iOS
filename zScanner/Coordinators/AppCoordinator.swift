//
//  AppCoordinator.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

class AppCoordinator: Coordinator {
    
    //MARK: - Instance part
    init() {
        let window = UIWindow(frame: UIScreen.main.bounds)
        super.init(window: window, navigationController: nil)
    }
    
    // MARK: Inteface
    func begin() {
  //      startLoginCoordinator()
      startDocumentsCoordinator()
    }
    
    // MARK: Helpers
    private func startLoginCoordinator() {
        let coordinator = LoginCoordinator(flowDelegate: self, window: window)
        addChildCoordinator(coordinator)
        coordinator.begin()
    }
    
    private func startDocumentsCoordinator() {
        let coordinator = DocumentsCoordinator(flowDelegate: self, window: window)
        addChildCoordinator(coordinator)
        coordinator.begin()
    }
}

// MARK: - LoginFlowDelegate implementation
extension AppCoordinator: LoginFlowDelegate {
    func successfulLogin() {
        startDocumentsCoordinator()
    }
}

// MARK: - DocumentsFlowDelegate implementation
extension AppCoordinator: DocumentsFlowDelegate {
    func logout() {
        startLoginCoordinator()
    }
}
