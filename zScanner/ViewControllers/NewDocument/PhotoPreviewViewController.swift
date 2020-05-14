//
//  PhotoPreviewViewController.swift
//  zScanner
//
//  Created by Jan Provazník on 07/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

class PhotoPreviewViewController: MediaPreviewViewController {

    // MARK: Instance part
    private var image: UIImage?
    
    // MARK: Lifecycle
    init(imageURL: URL, viewModel: MediaViewModel, coordinator: MediaPreviewCoordinator) {
        
        super.init(viewModel: viewModel, mediaType: .photo, mediaURL: imageURL, folderName: viewModel.folderName, coordinator: coordinator)
    }
    
    // MARK: View setup
    override func setupView() {
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.bottom.equalTo(buttonStackView.snp.top)
            make.top.leading.trailing.equalTo(safeArea)
        }
    }
    
    // MARK: Helpers
    override func loadMedia() {
        do {
            let data = try Data(contentsOf: mediaURL)
            image = UIImage(data: data)
        } catch(let error) {
            print("Could not load data from url: ", error)
        }
    }
    
    // MARK: Lazy instance part
    private lazy var imageView = UIImageView(image: image)
}
