//
//  BaseViewController.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol BaseCoordinator: class {
    func backButtonPressed(sender: BaseViewController)
    func willPreventPop(for sender: BaseViewController) -> Bool
    func didSwipeToPop()
}

// MARK: -
class BaseViewController: PluggableViewController {
    
    // MARK: Instance part
    private unowned let coordinator: BaseCoordinator
    
    init(coordinator: BaseCoordinator, services: [ViewControllerService] = [], theme: Theme = .light) {
        self.coordinator = coordinator
        self.injectedServices = services
        self.theme = theme == .light ? LightTheme() : DarkTheme()
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Properties
    private let injectedServices: [ViewControllerService]
    
    override var services: [ViewControllerService] {
        return super.services + injectedServices
    }
    
    var leftBarButtonItems: [UIBarButtonItem] { return [] } 
    var rightBarButtonItems: [UIBarButtonItem] { return [] }

    var theme: ThemeProtocol
    
    // MARK: ViewController's lifecycle
    override func loadView() {
        view = UIView()
        view.backgroundColor = .white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupNavBar()
        configureNavigationBarButtons()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        swipeToPopBegin = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if swipeToPopBegin {
            coordinator.didSwipeToPop()
        }
        swipeToPopBegin = false
    }
    
    // MARK: Helpers
    private enum SwipeState {
        case enabled, begin, null
    }
    
    private var swipeToPopBegin = false
    
    private func configureNavigationBarButtons() {
        guard let navigationController = navigationController else { return }
        
        navigationController.interactivePopGestureRecognizer?.delegate = self
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItems = leftBarButtonItems
        navigationItem.rightBarButtonItems = rightBarButtonItems
        
        setupBackButton()
    }
    
    func setupBackButton() {
        if (navigationController?.viewControllers.count ?? 0) > 1 {
            let backButton = BackButton()
            backButton.delegate = self
            navigationItem.leftBarButtonItems?.insert(backButton, at: 0)
        }
    }
    
    func setupNavBar() {
        navigationController?.navigationBar.barStyle = theme.navigationBarBarStyle
        navigationController?.navigationBar.titleTextAttributes = theme.navigationBarTitleTextAttributes
        navigationController?.navigationBar.tintColor = theme.navigationBarTintColor
    }
}

// MARK: - BackButtonDelegate implementation
extension BaseViewController: BackButtonDelegate {
    func didClickBack() {
        swipeToPopBegin = false
        coordinator.backButtonPressed(sender: self)
    }
}

extension BaseViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard navigationItem.leftBarButtonItems?.contains(where: { $0 is BackButton }) == true else { return false }
        
        if coordinator.willPreventPop(for: self) {
            coordinator.backButtonPressed(sender: self)
            return false
        }
        swipeToPopBegin = true
        return true
    }
}
