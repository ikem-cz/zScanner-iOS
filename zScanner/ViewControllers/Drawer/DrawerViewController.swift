//
//  DrawerViewController.swift
//  zScanner
//
//  Created by Martin Georgiu on 10/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol DrawerCoordinator: BaseCoordinator {
    func closeDrawer()
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
        view.addSubview(topStackView)
        view.addSubview(menuStackView)
        
        topStackView.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)


        topStackView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        topStackView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        topStackView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        
        drawerLogo.heightAnchor.constraint(equalToConstant: 102).isActive = true
        drawerLogo.widthAnchor.constraint(equalToConstant: 114).isActive = true
        
        menuStackView.topAnchor.constraint(equalTo: topStackView.bottomAnchor, constant: 15).isActive = true
        menuStackView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 15).isActive = true
        menuStackView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 15).isActive = true
    }
    
    @objc func handleMenuTap(_ sender : UIButton){
        coordinator.closeDrawer()
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
    
    func hideDrawer() {
        view.frame = CGRect(x: -view.frame.width, y: 0, width: view.frame.width, height: view.frame.height)
    }
    
    func showDrawer() {
        view.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
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
