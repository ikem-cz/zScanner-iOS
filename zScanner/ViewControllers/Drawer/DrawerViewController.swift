//
//  DrawerViewController.swift
//  zScanner
//
//  Created by Martin Georgiu on 10/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol DrawerCoordinator: BaseCoordinator {
    func logout()
    func showAbout()
    func refreshDocumentsList()
}


class DrawerViewController: BaseViewController, DrawerDelegate {
    private unowned let coordinator: DrawerCoordinator
    private let viewModel: DocumentsListViewModel
    
    init(viewModel: DocumentsListViewModel, coordinator: DrawerCoordinator) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        
        super.init(coordinator: coordinator)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupView()
    }
    
    private lazy var window: UIWindow = {
        guard let window = UIApplication.shared.keyWindow else { return UIWindow() }
        return window
    }()
    private lazy var width: CGFloat = {
        let width = window.frame.width * 2 / 3
        return width
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
    private lazy var rootDrawerView: UIView = {
        let rView = UIView()
        rView.backgroundColor = .white
        return rView
    }()
    
    private lazy var drawerMenuItems: [String] = [
        "drawer.logout.title".localized,
        "drawer.deleteHistory.title".localized,
        "drawer.aboutApp.title".localized
    ]

    
    private lazy var drawerLogo: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "menuLogo")
        imageView.contentMode = UIView.ContentMode.scaleAspectFit
        return imageView
    }()
    private lazy var drawerTopLabel: UILabel = {
        let label = UILabel()
        label.text = "zScanner"
        label.textColor = .white
        label.font = label.font.withSize(25)
        return label
    }()
    private lazy var topStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [drawerLogo,drawerTopLabel])
        stackView.axis = .vertical
        stackView.alignment = .top
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 10
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.spacing = UIStackView.spacingUseSystem

        stackView.addBackground(color: .primary)
        return stackView
    }()
  
    private func drawerMakeMenuButtons (_ names: [String]) -> [DrawerMenuButton] {
        var drawerMenu: [DrawerMenuButton] = []
        
        for drawerMenuItem in drawerMenuItems {
            let button = DrawerMenuButton()
            button.setTitle(drawerMenuItem, for: .normal)
            button.addTarget(self, action: #selector(handleMenuTap(_:)), for: .touchUpInside)

            drawerMenu.append(button)
        }
        return drawerMenu
       
    }
    private lazy var menuStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: drawerMakeMenuButtons(drawerMenuItems))
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 10
        stackView.distribution = .fill
        return stackView
    }()
    

    private func setupView() {
        window.addSubview(blackView)
        window.addSubview(rootDrawerView)
        rootDrawerView.addSubview(topStackView)
        rootDrawerView.addSubview(menuStackView)
        
        topStackView.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)


        topStackView.topAnchor.constraint(equalTo: rootDrawerView.topAnchor).isActive = true
        topStackView.leftAnchor.constraint(equalTo: rootDrawerView.leftAnchor).isActive = true
        topStackView.rightAnchor.constraint(equalTo: rootDrawerView.rightAnchor).isActive = true
        
        
        drawerLogo.heightAnchor.constraint(equalToConstant: 102).isActive = true
        drawerLogo.widthAnchor.constraint(equalToConstant: 114).isActive = true
        
        menuStackView.topAnchor.constraint(equalTo: topStackView.bottomAnchor, constant: 15).isActive = true
        menuStackView.leftAnchor.constraint(equalTo: rootDrawerView.leftAnchor, constant: 15).isActive = true
        menuStackView.rightAnchor.constraint(equalTo: rootDrawerView.rightAnchor, constant: 15).isActive = true
        
        blackView.topAnchor.constraint(equalTo: window.topAnchor).isActive = true
        blackView.bottomAnchor.constraint(equalTo: window.bottomAnchor).isActive = true
        blackView.leftAnchor.constraint(equalTo: window.leftAnchor).isActive = true
        blackView.rightAnchor.constraint(equalTo: window.rightAnchor).isActive = true

        rootDrawerView.frame = CGRect(x: -width, y: 0, width: width, height: window.frame.height)

    }
    
    
    @objc func handleMenuTap(_ sender : UIButton){
        handleDismiss()
        switch sender.title(for: .normal) {
        case drawerMenuItems[0]:
            viewModel.deleteHistory()
            coordinator.logout()
        case drawerMenuItems[1]:
            viewModel.deleteHistory()
            coordinator.refreshDocumentsList()
        case drawerMenuItems[2]:
            coordinator.showAbout()
        default:
            print("bug")
        }
        
    }
    
    @objc func handleDismiss() {
        UIView.animate(withDuration: 0.3) {
            self.blackView.alpha = 0
            self.rootDrawerView.frame = CGRect(x: -self.width, y: 0, width: self.rootDrawerView.frame.width, height: self.rootDrawerView.frame.height)
        }
    }
    
    func showDrawer() {
        UIView.animate(withDuration: 0.3) {
            self.blackView.alpha = 0.5
            self.rootDrawerView.frame = CGRect(x: 0, y: 0, width: self.rootDrawerView.frame.width, height: self.rootDrawerView.frame.height)
        }
    }
    
}

extension UIStackView {
    func addBackground(color: UIColor) {
        let subView = UIView(frame: bounds)
        subView.backgroundColor = color
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subView, at: 0)
    }
}
