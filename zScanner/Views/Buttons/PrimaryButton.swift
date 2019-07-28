//
//  PrimaryButton.swift
//  zScanner
//
//  Created by Jakub Skořepa on 21/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

class PrimaryButton: UIButton {
    
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
        backgroundColor = .primary
        setTitleColor(.onPrimary, for: .normal)
        layer.cornerRadius = 4
    }
}
