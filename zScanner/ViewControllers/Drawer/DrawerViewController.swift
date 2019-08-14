//
//  DrawerViewController.swift
//  zScanner
//
//  Created by Martin Georgiu on 10/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol DrawerCoordinator: BaseCoordinator {
    func closeMenu()
    func logout()
    func deleteHistory()
    func showAbout()
}

class DrawerViewController: BaseViewController {
    private unowned let coordinator: DrawerCoordinator
    
    init(coordinator: DrawerCoordinator) {
        self.coordinator = coordinator
        
        super.init(coordinator: coordinator)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupView()
    }
    
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
    
    private lazy var topView: UIView = {
        let topView = UIView()
        
        topView.addSubview(drawerLogo)
        topView.addSubview(drawerTopLabel)
        topView.translatesAutoresizingMaskIntoConstraints = false
        topView.backgroundColor = .primary
        
        return topView
    }()
  
    private func drawerMakeMenuButtons (_ names: [String]) -> [DrawerMenuButton] {
        var drawerMenu: [DrawerMenuButton] = []
        
        for drawerMenuItem in drawerMenuItems {
            let button = DrawerMenuButton()
            button.setTitle(drawerMenuItem, for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
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
        view.addSubview(topView)
        view.addSubview(menuStackView)
        
        // MARK: - Constraints
        topView.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
        }

        drawerLogo.snp.makeConstraints { make in
            make.height.equalTo(102)
            make.width.equalTo(114)
            make.top.equalTo(topView).offset(40)
            make.left.equalTo(topView).offset(20)
        }
        
        drawerTopLabel.snp.makeConstraints { make in
            make.top.equalTo(drawerLogo.snp.bottom).offset(20)
            make.left.equalTo(topView).offset(20)
            make.right.equalTo(topView).offset(20)
            make.bottom.equalTo(topView).offset(-20)
        }
        
        menuStackView.snp.makeConstraints { make in
            make.top.equalTo(topView.snp.bottom).offset(15)
            make.left.equalTo(view).offset(15)
            make.right.equalTo(view).offset(15)
        }
    }
    
    @objc func handleMenuTap(_ sender: UIButton){
        coordinator.closeMenu()
        switch sender.title(for: .normal) {
            
        case drawerMenuItems[0]:
            coordinator.deleteHistory()
            coordinator.logout()
            
        case drawerMenuItems[1]:
            coordinator.deleteHistory()
            
        case drawerMenuItems[2]:
            coordinator.showAbout()
            
        default:
            print("bug")
        }
    }
}
