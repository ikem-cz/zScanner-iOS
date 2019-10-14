//
//  DrawerMenuButton.swift
//  zScanner
//
//  Created by Martin Georgiu on 11/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

class DrawerMenuButton: UIButton {
    
    //MARK: Instance part
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Helpers
    private func setup() {
        contentHorizontalAlignment = .left
        titleLabel?.font = .body
        setTitleColor(.primary, for: .normal)
    }
}

