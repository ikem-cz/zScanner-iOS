//
//  PhotoSelectorCollectionViewCell.swift
//  zScanner
//
//  Created by Jakub Skořepa on 14/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol PhotoSelectorCellDelegate: class {
    func delete(media: Media)
}

// MARK: -
class PhotoSelectorCollectionViewCell: UICollectionViewCell {
    
    // MARK: Instance part
    private(set) var element: Media? {
        didSet {
            imageView.image = element?.thumbnail
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lifecycle
    override func prepareForReuse() {
        super.prepareForReuse()
        
        element = nil
    }
    
    // MARK: Interface
    func setup(with element: Media, delegate: PhotoSelectorCellDelegate) {
        self.element = element
        self.delegate = delegate
    }
    
    // MARK: Helpers
    private weak var delegate: PhotoSelectorCellDelegate?
    
    @objc private func deleteMedium() {
        guard let element = element else { return }
        delegate?.delete(media: element)
    }
    
    private func setupView() {
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.addSubview(deleteButton)
        deleteButton.snp.makeConstraints { make in
            make.width.height.equalTo(25)
            make.top.right.equalToSuperview().inset(4)
        }
        
        deleteButton.addTarget(self, action: #selector(deleteMedium), for: .touchUpInside)
    }
    
    private var imageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        return image
    }()
    
    private var deleteButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "delete").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        button.dropShadow()
        return button
    }()
}

