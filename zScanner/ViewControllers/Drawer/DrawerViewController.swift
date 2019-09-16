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

// MARK: -
class DrawerViewController: BaseViewController {
    
    // MARK: Instance part
    private unowned let coordinator: DrawerCoordinator
    private let login: LoginDomainModel
    
    init(login: LoginDomainModel, coordinator: DrawerCoordinator) {
        self.coordinator = coordinator
        self.login = login
        
        super.init(coordinator: coordinator)
    }
    
    // MARK: Lifecycle
    override func loadView() {
        super.loadView()
        setupView()
    }
    
    // MARK: Helpers
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
    
    private func setupView() {
        view.addSubview(topView)
        topView.addSubview(logo)
        topView.addSubview(drawerTopLabel)
        topView.addSubview(usernameLabel)
        
        view.addSubview(menuStackView)
        menuStackView.addArrangedSubview(logoutButton)
        menuStackView.addArrangedSubview(deleteHistoryButton)
        menuStackView.addArrangedSubview(aboutButton)
        
        topView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        logo.snp.makeConstraints { make in
            make.width.equalTo(114)
            make.height.equalTo(102)
            make.top.equalTo(topView.safeAreaLayoutGuide.snp.top).offset(40)
            make.left.equalToSuperview().offset(20)
        }
        
        drawerTopLabel.snp.makeConstraints { make in
            make.top.equalTo(logo.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(20)
        }
        
        usernameLabel.snp.makeConstraints { make in
            make.top.equalTo(drawerTopLabel.snp.bottom).offset(20)
            make.left.right.bottom.equalToSuperview().inset(20)
        }
        
        menuStackView.snp.makeConstraints { make in
            make.top.equalTo(topView.snp.bottom).offset(15)
            make.left.right.equalToSuperview().inset(20)
        }
    }
    
    private lazy var logo: UIImageView = {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "ikemLogo")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        imageView.backgroundColor = .primary
        return imageView
    }()

    private lazy var drawerTopLabel: UILabel = {
        let label = UILabel()
        label.text = "drawer.header.title".localized
        label.textColor = .white
        label.font = .headline
        return label
    }()

    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.text = String(format: "drawer.header.usernameFormat".localized, login.username)
        label.numberOfLines = 0
        label.textColor = .white
        label.font = .body
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
        button.titleLabel?.font = .body
        return button
    }()

    private lazy var deleteHistoryButton: DrawerMenuButton = {
        var button = DrawerMenuButton()
        button.setTitle("drawer.deleteHistory.title".localized, for: .normal)
        button.addTarget(self, action: #selector(handleMenuTap(_:)), for: .touchUpInside)
        button.titleLabel?.font = .body
        return button
    }()

    private lazy var aboutButton: DrawerMenuButton = {
        var button = DrawerMenuButton()
        button.setTitle("drawer.aboutApp.title".localized, for: .normal)
        button.addTarget(self, action: #selector(handleMenuTap(_:)), for: .touchUpInside)
        button.titleLabel?.font = .body
        return button
    }()

    private lazy var menuStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.distribution = .fill
        return stackView
    }()
}
