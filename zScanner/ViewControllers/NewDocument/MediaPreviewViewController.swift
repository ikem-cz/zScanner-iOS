//
//  MediaPreviewViewController.swift
//  zScanner
//
//  Created by Jan Provazník on 07/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol PhotoPreviewCoordinator: BaseCoordinator {
    func photoApproved()
    func createNewPhoto()
}

class PhotoPreviewViewController: BaseViewController {

    // MARK: Instance part
    private let imageURL: URL
    private var image: UIImage?
    
    private unowned let coordinator: PhotoPreviewCoordinator
    
    // MARK: Lifecycle
    init(imageURL: URL, coordinator: PhotoPreviewCoordinator) {
        self.imageURL = imageURL
        self.coordinator = coordinator
        
        super.init(coordinator: coordinator)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadImage()
        setupView()
    }
    
    
    func setupView() {
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: Helpers
    private func loadImage() {
        do {
            let data = try Data(contentsOf: imageURL)
            image = UIImage(data: data)
        } catch(let error) {
            print("Could not load data from url: ", error)
        }
    }
     
    // MARK: Lazy instance part
    private lazy var imageView = UIImageView(image: image)
    
}
