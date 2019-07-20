//
//  LoginViewController.swift
//  zScanner
//
//  Created by Jakub Skořepa on 13/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import SnapKit

protocol LoginViewDelegate: BaseCoordinator {
    func successfulLogin()
}

class LoginViewController: BaseViewController {

    // MARK: - Instance part
    private unowned let coordinator: LoginViewDelegate
    private let viewModel: LoginViewModel
    
    init(viewModel: LoginViewModel, coordinator: LoginViewDelegate, services: [ViewControllerService] = []) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        super.init(coordinator: coordinator, services: services)
    }

    override func loadView() {
        super.loadView()
        
        setupView()
    }
    
    // MARK: - Helpers
    private func setupView() {
        view.addSubview(container)
        
        container.snp.makeConstraints { make in
            make.center.equalTo(safeArea)
            make.width.equalTo(200)
        }
        
        container.addSubview(logoView)
        logoView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
        }
        
        container.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(logoView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.right.left.equalToSuperview()
        }
        
        container.addSubview(usernameTextField)
        usernameTextField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.right.left.equalToSuperview()
        }
        
        container.addSubview(passwordTextField)
        passwordTextField.snp.makeConstraints { make in
            make.top.equalTo(usernameTextField.snp.bottom).offset(8)
            make.bottom.centerX.equalToSuperview()
            make.right.left.equalToSuperview()
        }
        
        titleLabel.text = "zScanner"
    }
    
    private lazy var logoView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        return image
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .primary
        label.font = .headline
        label.textAlignment = .center
        return label
    }()
    
    private lazy var usernameTextField: UITextField = {
        let textField = UITextField()
        textField.textContentType = .username
        textField.placeholder = "LOGIN_USERNAME_PLACEHOLDER".localized
        textField.setBottomBorder()
        return textField
    }()
    
    private lazy var passwordTextField: UITextField = {
        let textField = UITextField()
        textField.textContentType = .password
        textField.isSecureTextEntry = true
        textField.placeholder = "LOGIN_PASSWORD_PLACEHOLDER".localized
        textField.setBottomBorder()
        return textField
    }()
    
    private lazy var container: UIView = {
        let view = UIView()
        return view
    }()
}

