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
    
    // MARK: - Instance part
    private unowned let coordinator: DrawerCoordinator
    
    init(coordinator: DrawerCoordinator) {
        self.coordinator = coordinator
        
        super.init(coordinator: coordinator)
    }
    
    // MARK: Lifecycle
    override func loadView() {
        super.loadView()
        setupView()
    }
    
    // MARK: Helpers
    private lazy var drawerLogo: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "menuLogo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var drawerTopLabel: UILabel = {
        let label = UILabel()
        label.text = "drawer.header.title".localized
        label.textColor = .white
        label.font = .headline
        return label
    }()
    
    private lazy var topView: UIView = {
        let topView = UIView()
        topView.backgroundColor = .primary
        return topView
    }()
  
    private lazy var logoutButton: DrawerMenuButton = {
        var button = DrawerMenuButton()
        button.setTitle("drawer.logout.title".localized, for: .normal)
        button.addTarget(self, action: #selector(handleMenuTap(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var deleteHistoryButton: DrawerMenuButton = {
        var button = DrawerMenuButton()
        button.setTitle("drawer.deleteHistory.title".localized, for: .normal)
        button.addTarget(self, action: #selector(handleMenuTap(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var aboutButton: DrawerMenuButton = {
        var button = DrawerMenuButton()
        button.setTitle("drawer.aboutApp.title".localized, for: .normal)
        button.addTarget(self, action: #selector(handleMenuTap(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var menuStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.distribution = .fill
        return stackView
    }()

    private func setupView() {
        topView.addSubview(drawerLogo)
        topView.addSubview(drawerTopLabel)
        
        menuStackView.addArrangedSubview(logoutButton)
        menuStackView.addArrangedSubview(deleteHistoryButton)
        menuStackView.addArrangedSubview(aboutButton)
        
        
        view.addSubview(topView)
        view.addSubview(menuStackView)
        
        // MARK: - Constraints
        topView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        drawerLogo.snp.makeConstraints { make in
            make.height.equalTo(102)
            make.width.equalTo(114)
            make.top.equalToSuperview().offset(40)
            make.left.equalToSuperview().offset(20)
        }
        
        drawerTopLabel.snp.makeConstraints { make in
            make.top.equalTo(drawerLogo.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview().inset(20)
        }
        
        menuStackView.snp.makeConstraints { make in
            make.top.equalTo(topView.snp.bottom).offset(15)
            make.left.right.equalToSuperview().inset(15)
        }
    }
    
    @objc private func handleMenuTap(_ sender: UIButton) {
        switch sender {
        case logoutButton:
            coordinator.deleteHistory()
            coordinator.closeMenu()
            coordinator.logout()
            
        case deleteHistoryButton:
            coordinator.deleteHistory()
            coordinator.closeMenu()
            
        case aboutButton:
            coordinator.closeMenu()
            coordinator.showAbout()
            
        default:
            assertionFailure()
        }
    }
}
