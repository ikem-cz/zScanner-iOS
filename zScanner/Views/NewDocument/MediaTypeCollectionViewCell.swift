//
//  MediaTypeCollectionViewCell.swift
//  zScanner
//
//  Created by Jan Provazník on 01/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

class MediaTypeCollectionViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Interface
    func setup(with title: String) {
        titleLabel.text = title
    }
    
    // MARK: Helpers
    private func setupView() {
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.bottom.equalToSuperview()
        }
    }
    
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .body
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        return titleLabel
    }()
}
