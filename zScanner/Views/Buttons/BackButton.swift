//
//  BackButton.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol BackButtonDelegate: class {
    func didClickBack()
}

// MARK: -
class BackButton: UIBarButtonItem {
    
    // MARK: Instance part
    weak var delegate: BackButtonDelegate?
    
    override init() {
        super.init()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Helpers
    private func setup() {
        let view = UIView()
        let image = UIImageView(image: #imageLiteral(resourceName: "backButton"))
        view.addSubview(image)
        
        image.snp.makeConstraints { make in
            make.centerY.left.equalToSuperview()
        }
        
        view.snp.makeConstraints { make in
            make.width.equalTo(32)
            make.height.equalTo(44)
        }
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didClick)))
        customView = view
    }
    
    @objc private func didClick() {
        delegate?.didClickBack()
    }
}

