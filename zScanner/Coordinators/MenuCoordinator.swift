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

    init(flowDelegate: MenuFlowDelegate, window: UIWindow, navigationController: UINavigationController? = nil) {
        self.flowDelegate = flowDelegate

        super.init(window: window, navigationController: navigationController)

    }
    private lazy var viewController: DrawerViewController = {
        return DrawerViewController(coordinator: self)
    }()
    
    private lazy var blackView: UIView = {
        let bView = UIView()
        bView.backgroundColor = .black
        bView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss)))
        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleDismiss))
        swipeLeftGesture.direction = .left
        bView.addGestureRecognizer(swipeLeftGesture)
        bView.translatesAutoresizingMaskIntoConstraints = false
        bView.alpha = 0
        return bView
    }()
    private lazy var width: CGFloat = {
        let width = window.frame.width * 2 / 3
        return width
    }()

    func begin() {
        window.addSubview(blackView)
        window.addSubview(viewController.view)
        
        
        blackView.topAnchor.constraint(equalTo: window.topAnchor).isActive = true
        blackView.bottomAnchor.constraint(equalTo: window.bottomAnchor).isActive = true
        blackView.leftAnchor.constraint(equalTo: window.leftAnchor).isActive = true
        blackView.rightAnchor.constraint(equalTo: window.rightAnchor).isActive = true
        
        viewController.view.frame = CGRect(x: -width, y: 0, width: width, height: window.frame.height)
    }
    func openDrawer() {
        UIView.animate(withDuration: 0.3) {
            self.blackView.alpha = 0.5
            self.viewController.showDrawer()
        }
    }
    func closeDrawer() {
        UIView.animate(withDuration: 0.3) {
            self.blackView.alpha = 0
            self.viewController.hideDrawer()
        }
    }
    @objc private func handleDismiss(){
        closeDrawer()
    }
    func showAbout() {
        let aboutVC = AboutViewController(coordinator: self)
        push(aboutVC)
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
}
