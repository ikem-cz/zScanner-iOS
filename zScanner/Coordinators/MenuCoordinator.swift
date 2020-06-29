//
//  MenuCoordinator.swift
//  zScanner
//
//  Created by Martin Georgiu on 13/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol MenuFlowDelegate: FlowDelegate {
    func logout()
    func deleteHistory()
}

class MenuCoordinator: Coordinator {
    
    // MARK: Instance part
    unowned private let flowDelegate: MenuFlowDelegate
    private let login: LoginDomainModel

    init(login: LoginDomainModel, flowDelegate: MenuFlowDelegate, window: UIWindow, navigationController: UINavigationController? = nil) {
        self.login = login
        self.flowDelegate = flowDelegate

        super.init(flowDelegate: flowDelegate, window: window, navigationController: navigationController)
    }
    
    // MARK: Interface
    func begin() {
        installDrawerSreen()
    }
    
    func openMenu() {
        UIView.animate(withDuration: 0.3) {
            self.blackView.alpha = 0.5
            self.drawerViewController.view.frame.origin = CGPoint(x: 0, y: 0)
        }
        navigationController?.topViewController?.viewWillDisappear(true)
    }
    
    func closeMenu() {
        UIView.animate(withDuration: 0.3) {
            self.blackView.alpha = 0
            self.drawerViewController.view.frame.origin = CGPoint(x: -self.drawerViewController.view.frame.width, y: 0)
        }
        navigationController?.topViewController?.viewWillAppear(true)
    }
    
    // MARK: Helpers
    private func showAboutScreen() {
        let aboutViewController = AboutViewController(coordinator: self)
        push(aboutViewController)
    }
    
    private lazy var drawerViewController: DrawerViewController = {
        return DrawerViewController(login: login, coordinator: self)
    }()
    
    private lazy var blackView: UIView = {
        let blackView = UIView()
        blackView.backgroundColor = .black
        blackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss)))
        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleDismiss))
        swipeLeftGesture.direction = .left
        blackView.addGestureRecognizer(swipeLeftGesture)
        blackView.alpha = 0
        return blackView
    }()
    
    private lazy var menuWidth: CGFloat = {
        let width = window.frame.width * 2 / 3
        return width
    }()
    
    private func installDrawerSreen() {
        window.addSubview(blackView)
        window.addSubview(drawerViewController.view)
        
        blackView.snp.makeConstraints { make in
            make.edges.equalTo(window)
        }
        
        drawerViewController.view.frame = CGRect(x: -menuWidth, y: 0, width: menuWidth, height: window.frame.height)
    }
    
    @objc private func handleDismiss(){
        closeMenu()
    }
}

// MARK: - DrawerCoordinator implementation
extension MenuCoordinator: DrawerCoordinator {
    func logout() {
        flowDelegate.logout()
    }
    
    func deleteHistory() {
        flowDelegate.deleteHistory()
    }
    
    func showAbout() {
        showAboutScreen()
    }
}
