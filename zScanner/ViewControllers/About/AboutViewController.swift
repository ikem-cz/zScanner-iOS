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
    private unowned let coordinator: MenuCoordinator
    
    init(coordinator: MenuCoordinator) {
        self.coordinator = coordinator
        super.init(coordinator: coordinator)
    }
    
    // MARK: Lifecycle
    override func loadView() {
        super.loadView()
        
        setupView()
    }
    
    // MARK: Helpers
    private func setupView() {
        navigationItem.title = "drawer.aboutApp.title".localized
      
        stackView.addArrangedSubview(drawerLogo)
        stackView.addArrangedSubview(aboutHeader)
        stackView.addArrangedSubview(aboutParagraph)
        stackView.addArrangedSubview(aboutCopyright)

        view.addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(safeArea).inset(20)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().multipliedBy(0.666).priority(900)
            make.width.equalToSuperview().multipliedBy(0.85)
        }
        
        drawerLogo.snp.makeConstraints { make in
            make.height.equalTo(102)
            make.width.equalTo(114)
        }
    }
    
    private lazy var drawerLogo: UIImageView = {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "ikemLogo")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        imageView.backgroundColor = .primary
        return imageView
    }()
    
    private lazy var aboutHeader: UILabel = {
        let label = UILabel()
        label.text = "about.header.title".localized
        label.textColor = .primary
        label.font = .headline
        return label
    }()
    
    private lazy var aboutParagraph: UILabel = {
        let label = UILabel()
        label.text = "about.info.paragraph".localized
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .body
        label.textColor = .primary
        return label
    }()
    
    private lazy var aboutCopyright: UILabel = {
        let label = UILabel()
        label.text = "about.copyright.title".localized
        label.textAlignment = .center
        label.textColor = .primary
        label.font = .footnote
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 15
        return stackView
    }()
}
