//
//  PhotoSelectorCollectionViewCell.swift
//  zScanner
//
//  Created by Jakub Skořepa on 14/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol PhotoSelectorCellDelegate: class {
    func edit(media: Media)
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
    
    @objc private func editMedia() {
        guard let element = element else { return }
        delegate?.edit(media: element)
    }
    
    @objc private func deleteMedia() {
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
            make.height.equalTo(26)
            make.top.right.equalToSuperview().inset(6)
        }
        
        deleteButton.addTarget(self, action: #selector(deleteMedia), for: .touchUpInside)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(editMedia))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }
    
    private var imageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        return image
    }()
    
    private var deleteButton: UIButton = {
        let button = UIButton()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .light, scale: .large)
        button.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: imageConfig)?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .gray

        button.setTitle("Odstranit", for: .normal)
        button.setTitleColor(.gray, for: .normal)
        button.titleLabel?.font = .footnote

        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 16)
        button.imageEdgeInsets = UIEdgeInsets(top: -1, left: 0, bottom: -1, right: 0)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        button.layer.cornerRadius = 13
        button.dropShadow()
        return button
    }()
}
//
//private var deleteButton: UIButton = {
//    let button = UIButton()
//    button.setImage(#imageLiteral(resourceName: "delete").withRenderingMode(.alwaysTemplate), for: .normal)
//    button.setTitle("Odstranit", for: .normal)
//    button.tintColor = .white
//    button.backgroundColor = .red// UIColor.white.withAlphaComponent(0.3)
//    button.roundCorners(radius: 12.5)
//    button.dropShadow()
//    return button
//}()
