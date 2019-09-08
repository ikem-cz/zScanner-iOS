//
//  AppCoordinator.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

var isReady: Bool {
    return SeaCatClient.isReady()
}

class AppCoordinator: Coordinator {
    
    //MARK: - Instance part
    init() {
        let window = UIWindow(frame: UIScreen.main.bounds)
        super.init(window: window, navigationController: nil)
    }
    
    // MARK: Inteface
    func begin() {
        // Skip waiting in case of superfast SeaCat init. (with existing credentials)
        if SeaCatClient.isReady() {
            startDocumentsCoordinator()
        } else {
            showSplashScreen()
        }
    }
    
    // MARK: Helpers
    private func showSplashScreen() {
        let viewController = SeaCatSplashViewController(coordinator: self)
        changeWindowControllerTo(viewController)
    }
    
    private func runLoginFlow() {
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

// MARK: - SeaCatSplashCoordinator implementation
extension AppCoordinator: SeaCatSplashCoordinator {
    func seaCatInitialized() {
        
        // It's not about SeaCat is ready but more about certificate exists.
        // In this case we are creating certificate with credentials on login.
        // Therefore is more like credentials exists -> is logged in
        if SeaCatClient.isReady() {
            self.startDocumentsCoordinator()
        } else {
            self.runLoginFlow()
        }
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
        SeaCatClient.reset()
        runLoginFlow()
    }
}
