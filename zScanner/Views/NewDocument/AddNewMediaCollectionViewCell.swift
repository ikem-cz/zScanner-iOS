//
//  AddNewMediaCollectionViewCell.swift
//  zScanner
//
//  Created by Jan Provazník on 28/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol AddNewMediaCellDelegate: class {
    func createNewMedia()
}

class AddNewMediaCollectionViewCell: UICollectionViewCell {
    
    // MARK: Instance part
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Interface
    func setup(delegate: AddNewMediaCellDelegate) {
        self.delegate = delegate
    }
    
    // MARK: Helpers
    private weak var delegate: AddNewMediaCellDelegate?
    
    private func setupView() {
        backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        
        stackView.addArrangedSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.height.width.equalTo(40)
        }
        
        stackView.addArrangedSubview(titleLabel)
        
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(createNewMedia))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }
    
    @objc func createNewMedia() {
        delegate?.createNewMedia()
    }
    
    private var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.axis = .vertical
        return stackView
    }()
    
    private var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "plus"))
        imageView.tintColor = .darkGray
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .body
        label.textAlignment = .center
        label.textColor = .darkGray
        label.text = "newDocumentPhotos.nextPhoto.title".localized
        return label
    }()
}
