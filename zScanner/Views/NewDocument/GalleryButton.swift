//
//  GalleryButton.swift
//  zScanner
//
//  Created by Jan Provazník on 04/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import SnapKit

class GalleryButton: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        addSubview(galleryImage)
        galleryImage.snp.makeConstraints{ make in
            make.height.width.equalTo(40)
            make.top.centerX.equalToSuperview()
        }
        
        addSubview(galleryLabel)
        galleryLabel.snp.makeConstraints { make in
            make.top.equalTo(galleryImage.snp.bottom).inset(-10)
            make.bottom.leading.trailing.equalToSuperview()
        }
    }
    
    private lazy var galleryImage = UIImageView(image: #imageLiteral(resourceName: "photoLibrary"))
    
    private lazy var galleryLabel: UILabel = {
        let galleryLabel = UILabel()
        galleryLabel.font = .footnote
        galleryLabel.textColor = .white
        galleryLabel.text = "newDocumentPhotos.actioSheet.galleryAction".localized
        return galleryLabel
    }()
}
