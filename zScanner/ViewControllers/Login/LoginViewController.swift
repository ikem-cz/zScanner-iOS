//
//  LoginViewController.swift
//  zScanner
//
//  Created by Jakub Skořepa on 13/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

protocol LoginViewDelegate: BaseCoordinator {
    func successfulLogin()
}

class LoginViewController: BaseViewController {

    // MARK: Instance part
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBindings()
    }
    
    // MARK: Helpers
    
    private let disposeBag = DisposeBag()
    
    private func setupBindings() {
        usernameTextField.placeholder = viewModel.usernameField.title
        usernameTextField.rx.text
            .orEmpty
            .bind(to: viewModel.usernameField.text)
            .disposed(by: disposeBag)
        
        passwordTextField.placeholder = viewModel.passwordField.title
        passwordTextField.rx.text
            .orEmpty
            .bind(to: viewModel.passwordField.text)
            .disposed(by: disposeBag)
        
        passwordToggleButton.rx.tap.subscribe(onNext: { [weak self] status in
            self?.viewModel.passwordField.protected.toggle()
        }).disposed(by: disposeBag)
        
        viewModel.isValid.bind(to: loginButton.rx.isEnabled).disposed(by: disposeBag)
        
        loginButton.rx.tap.do(onNext: { [weak self] in
            self?.usernameTextField.resignFirstResponder()
            self?.passwordTextField.resignFirstResponder()
        })
        .subscribe(onNext: { [weak self] in
            self?.viewModel.signin()
        }).disposed(by: disposeBag)
        
        viewModel.status.subscribe(onNext: { [weak self] status in
            switch status {
            case .success:
               self?.coordinator.successfulLogin()
            default:
                break
            }
        }).disposed(by: disposeBag)
        
        viewModel.passwordField.protected.subscribe(onNext: { [weak self] status in
            guard let toggleButton = self?.passwordToggleButton else { return }
            
            toggleButton.isSelected = status ? false : true
            self?.passwordTextField.isSecureTextEntry = status
        }).disposed(by: disposeBag)
    }
    
    private func setupView() {
        view.addSubview(container)
        
        container.snp.makeConstraints { make in
            make.centerX.equalTo(safeArea)
            make.centerY.equalTo(safeArea).offset(-100)
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
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.right.left.equalToSuperview()
        }

        container.addSubview(passwordContainer)
        passwordContainer.snp.makeConstraints { make in
            make.top.equalTo(usernameTextField.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        
        passwordContainer.addSubview(passwordTextField)
        passwordTextField.snp.makeConstraints { make in
            make.top.left.bottom.equalToSuperview()
        }

        passwordContainer.addSubview(passwordToggleButton)
        passwordToggleButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        passwordToggleButton.snp.makeConstraints { make in
            make.top.right.bottom.equalToSuperview()
            make.left.equalTo(passwordTextField.snp.right).inset(-5)
        }
        
        container.addSubview(loginButton)
        loginButton.snp.makeConstraints { make in
            make.top.equalTo(passwordContainer.snp.bottom).offset(40)
            make.bottom.centerX.equalToSuperview()
            make.right.left.equalToSuperview().inset(20)
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
        textField.setBottomBorder()
        return textField
    }()
    
    private lazy var passwordTextField: UITextField = {
        let textField = PasswordTextField()
        textField.textContentType = .password
        textField.isSecureTextEntry = true
        textField.setBottomBorder()
        return textField
    }()
    
    private lazy var passwordToggleButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(#imageLiteral(resourceName: "eyeClose"), for: .normal)
        button.setImage(#imageLiteral(resourceName: "eyeOpen"), for: .selected)
        return button
    }()
    
    private lazy var loginButton: PrimaryButton = {
        let button = PrimaryButton()
        button.setTitle("login.button.title".localized, for: .normal)
        return button
    }()
    
    private lazy var passwordContainer = UIView()
    
    private lazy var container: UIView = {
        let view = UIView()
        return view
    }()
}

