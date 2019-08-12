//
//  AboutViewController.swift
//  zScanner
//
//  Created by Martin Georgiu on 11/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

class AboutViewController: BaseViewController {
    
    // MARK: - Instance part
    private unowned let coordinator: DocumentsCoordinator
    
    
    init(coordinator: DocumentsCoordinator) {
        self.coordinator = coordinator
        super.init(coordinator: coordinator)
    }
    
    
    override func loadView() {
        super.loadView()
        
        setupView()
        
    }
    private lazy var drawerLogo: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "menuLogo"))
        imageView.contentMode = UIView.ContentMode.scaleAspectFit
        imageView.backgroundColor = .primary
        return imageView
    }()
    private lazy var aboutHeader: UILabel = {
        let label = UILabel()
        label.text = "about.header.title".localized
        label.textColor = .primary
        label.font = label.font.withSize(30)
        return label
    }()
    private lazy var aboutParagraph: UILabel = {
        let label = UILabel()
        label.text = "about.info.paragraph".localized
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .primary
        return label
    }()
    private lazy var aboutCopyright: UILabel = {
        let label = UILabel()
        label.text = "about.copyright.title".localized
        label.textAlignment = .center
        label.textColor = .primary
        label.font = label.font.withSize(14)
        return label
    }()
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [drawerLogo,aboutHeader, aboutParagraph, aboutCopyright])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 15
        return stackView
    }()
    
    func setupView() {
        navigationItem.title = "drawer.aboutApp.title".localized
      
        self.view.addSubview(stackView)
        
        // MARK: - Constraints
        stackView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        stackView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        stackView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.85).isActive = true
        drawerLogo.heightAnchor.constraint(equalToConstant: 102).isActive = true
        drawerLogo.widthAnchor.constraint(equalToConstant: 114).isActive = true

    }
}


