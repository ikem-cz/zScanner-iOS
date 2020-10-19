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
        
        view.addSubview(byIkem)
        byIkem.snp.makeConstraints { make in
            make.centerX.equalTo(safeArea)
            make.bottom.equalTo(safeArea).inset(20)
            make.width.equalTo(150)
            make.height.equalTo(66)
        }
      
        stackView.addArrangedSubview(drawerLogo)
        stackView.addArrangedSubview(aboutParagraph)
        stackView.addArrangedSubview(aboutCopyright)
        stackView.addArrangedSubview(versionLabel)

        view.addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(safeArea).inset(20)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().multipliedBy(0.666).priority(500)
            make.width.equalToSuperview().multipliedBy(0.85)
        }
        
        drawerLogo.snp.makeConstraints { make in
            make.width.equalTo(118)
            make.height.equalTo(180)
        }
    }
    
    private lazy var drawerLogo: UIImageView = {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "zScanner_colored")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var aboutParagraph: UILabel = {
        let label = UILabel()
        label.text = "about.info.paragraph".localized
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .body
        label.textColor = .black
        return label
    }()
    
    private lazy var aboutCopyright: UILabel = {
        let label = UILabel()
        label.text = "about.copyright.title".localized
        label.textAlignment = .center
        label.textColor = .black
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
    
    private lazy var versionLabel: UILabel = {
        let label = UILabel()
        label.text = Bundle.main.formattedVersion
        label.textAlignment = .center
        label.textColor = .black
        label.font = .footnote
        return label
    }()
    
    private lazy var byIkem: UIImageView = {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "By Ikem").withRenderingMode(.alwaysTemplate)
        imageView.tintColor = .black
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
}
