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
        image = #imageLiteral(resourceName: "backButton")
        action = #selector(didClick)
    }
    
    @objc private func didClick() {
        delegate?.didClickBack()
    }
}

