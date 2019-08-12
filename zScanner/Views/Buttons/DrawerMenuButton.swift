//
//  DrawerMenuButton.swift
//  zScanner
//
//  Created by Martin Georgiu on 11/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

// MARK: -
class DrawerMenuButton: UIButton {
    
    //MARK: Instance part
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override var isEnabled: Bool{
        didSet {
            alpha = isEnabled ? 1.0 : 0.5
        }
    }
    
    //MARK: Helpers
    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        contentHorizontalAlignment = .left
        setTitleColor(.primary, for: .normal)
    }
}

