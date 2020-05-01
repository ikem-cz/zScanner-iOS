//
//  MediaTypeCollectionViewCell.swift
//  zScanner
//
//  Created by Jan Provazník on 01/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

class MediaTypeCollectionViewCell: UICollectionViewCell {
    // MARK: Interface
    func setup(with title: String) {
        titleLabel.text = title
    }
    
    // MARK: Helpers
    private func setupView() {
        titleLabel.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
        }
    }
    
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .body
        titleLabel.textColor = .red
        titleLabel.textAlignment = .center
        return titleLabel
    }()
}
