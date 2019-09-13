//
//  SplashViewController.swift
//  zScanner
//
//  Created by Jakub Skořepa on 07/09/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol SeaCatSplashCoordinator: BaseCoordinator {
    func seaCatInitialized()
}

class SeaCatSplashViewController: BaseViewController, ErrorHandling {
    
    private unowned let coordinator: SeaCatSplashCoordinator

    init(coordinator: SeaCatSplashCoordinator) {
        self.coordinator = coordinator
        super.init(coordinator: coordinator)
    }

    override func loadView() {
        guard let launchScreen = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController() else {
            super.loadView()
            return
        }
        
        let launchView = launchScreen.view
        launchScreen.view = nil
        view = launchView
    }

    override func viewDidAppear(_ animated: Bool) {
        waitForSeaCat()
    }
    
    // MARK: SeaCat
    private var seaCatTimer: Timer?
    private var timeoutTimer: Timer?
   
    private func waitForSeaCat() {
        guard Reachability.isConnectedToNetwork() else {
            handleError(RequestError(.noInternetConnection), okCallback: nil, retryCallback: { [weak self] in
                self?.waitForSeaCat()
            })
            return
        }
        
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
            
            // Give SeaCat a little bit extra time to init 😤😖
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.coordinator.seaCatInitialized()
            }
        }
    }

    @objc private func timeout() {
        SeaCatClient.reset()
    }
}
