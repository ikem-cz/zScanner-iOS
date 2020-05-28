//
//  HambugerButton.swift
//  zScanner
//
//  Created by Jan Provazník on 18/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

class HambugerButton: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(imageView)
        imageView.snp.makeConstraints{ make in
            make.top.bottom.left.equalToSuperview()
            make.width.equalTo(25)
        }
        
        addSubview(userlabel)
        userlabel.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
            make.left.equalTo(imageView.snp.right).offset(8)
        }
    }
    
    func setup(username: String) {
        userlabel.text = username
    }
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "menuIcon")
        imageView.tintColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        return imageView
    }()
    
    private lazy var userlabel: UILabel = {
        let label = UILabel()
        label.textColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        label.numberOfLines = 0
        label.font = .footnote
        return label
    }()
}
