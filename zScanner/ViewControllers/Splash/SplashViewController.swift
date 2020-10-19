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
        
        setupView()
    }

    override func viewDidAppear(_ animated: Bool) {
        checkInternetConnection()
    }
    
    // MARK: SeaCat
    private var seaCatTimer: Timer?
    private var timeoutTimer: Timer?
    private let reachability = try! Reachability()
    
    private func checkInternetConnection() {
        if reachability.connection == .unavailable {
            NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
            try? reachability.startNotifier()
            
            infoLabel.text = "splash.waitingForInternet.message".localized
            handleError(RequestError(.noInternetConnection), okCallback: nil, retryCallback: nil)
        } else {
            initializeSeaCat()
        }
    }
    
    @objc func reachabilityChanged(note: Notification) {
        guard let reachability = note.object as? Reachability else { return }

        switch reachability.connection {
        case .cellular, .wifi:
            reachability.stopNotifier()
            NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: reachability)
            initializeSeaCat()
        case .unavailable, .none:
            break
        }
    }
   
    private func initializeSeaCat() {
        SeaCatClient.configure(with: nil)
        SeaCatClient.setLogMask(SCLogFlag(rawValue: 0))
        
        infoLabel.text = "splash.waitingForSeaCat.message".localized
        
        SeaCatClient.addObserver(self, selector: #selector(seaCatStateChanged), name: SeaCat_Notification_StateChanged)
        seaCatTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(seaCatStateChanged), userInfo: nil, repeats: true)
        timeoutTimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(timeout), userInfo: nil, repeats: false)
        seaCatStateChanged()
    }

    @objc private func seaCatStateChanged() {
        guard let state = SeaCatClient.getState() else { return }
       
        if state[1] == "C" || SeaCatClient.isReady() {
            seaCatTimer?.invalidate()
            timeoutTimer?.invalidate()
            SeaCatClient.removeObserver(self)
            
            DispatchQueue.main.async {
                self.coordinator.seaCatInitialized()
            }
        }
    }

    @objc private func timeout() {
        SeaCatClient.reset()
    }
    
    private func setupView() {
        guard let byIkem = view.subviews.last(where: { $0 is UIImageView }) else { return }
        
        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(byIkem.snp.top).offset(-30)
        }
        
        container.addSubview(infoLabel)
        infoLabel.snp.makeConstraints { make in
            make.top.bottom.left.equalToSuperview()
        }
        
        container.addSubview(loading)
        loading.snp.makeConstraints { make in
            make.right.centerY.equalToSuperview()
            make.left.equalTo(infoLabel.snp.right).offset(8)
        }
    }
    
    private lazy var container = UIView()
    
    private lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .footnote
        return label
    }()
    
    private lazy var loading: UIActivityIndicatorView = {
        let loading = UIActivityIndicatorView(style: .medium)
        loading.color = .white
        loading.startAnimating()
        return loading
    }()
}
