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
    init(media: Media, viewModel: MediaListViewModel, coordinator: MediaPreviewCoordinator) {
        
        super.init(viewModel: viewModel, media: media, coordinator: coordinator)
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
            let data = try Data(contentsOf: media.url)
            image = UIImage(data: data)
        } catch(let error) {
            print("Could not load data from url: ", error)
        }
    }
    
    // MARK: Lazy instance part
    private lazy var imageView = UIImageView(image: image)
}
