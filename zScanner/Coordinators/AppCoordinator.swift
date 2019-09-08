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
        if SeaCatClient.isReady() {
            startDocumentsCoordinator()
        } else {
            showSplashScreen()
            waitForSeaCat()
        }
    }
    
    // MARK: Helpers
    private func showSplashScreen() {
        guard let viewController = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController() else { return }
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
    
    // MARK: SeaCat
    private var seaCatTimer: Timer?
    private var timeoutTimer: Timer?
    
    private func waitForSeaCat() {
        SeaCatClient.addObserver(self, selector: #selector(seaCatStateChanged), name: SeaCat_Notification_StateChanged)
        seaCatTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(seaCatStateChanged), userInfo: nil, repeats: true)
        timeoutTimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(timeout), userInfo: nil, repeats: false)
        seaCatStateChanged()
    }
    
    @objc private func seaCatStateChanged() {
        guard let state = SeaCatClient.getState() else { return }
        
        if state[1] == "C" || state[1] == "*" {
            seaCatTimer?.invalidate()
            timeoutTimer?.invalidate()
            SeaCatClient.removeObserver(self)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if SeaCatClient.isReady() {
                    self.startDocumentsCoordinator()
                } else {
                    self.runLoginFlow()
                }
            }
        }
    }
    
    @objc private func timeout() {
        SeaCatClient.reset()
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
