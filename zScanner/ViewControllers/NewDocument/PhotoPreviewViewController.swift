//
//  PhotoPreviewViewController.swift
//  zScanner
//
//  Created by Jan Provazník on 07/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol PhotoPreviewCoordinator: BaseCoordinator {
    func photoApproved(image: UIImage, fromGallery: Bool)
    func createNewPhoto()
}

class PhotoPreviewViewController: BaseViewController {

    // MARK: Instance part
    private let imageURL: URL
    private var image: UIImage?
    
    private unowned let coordinator: PhotoPreviewCoordinator
    private let folderName: String
    
    private var navigationBarTitleTextAttributes: [NSAttributedString.Key : Any]?
    private var navigationBarBarStyle: UIBarStyle? // Background-color of the navigation controller, which automatically adapts the color of the status bar (time, battery ..)
    override var navigationBarTintColor: UIColor? { .white } // Color of navigation controller items
    
    // MARK: Lifecycle
    init(imageURL: URL, folderName: String, coordinator: PhotoPreviewCoordinator) {
        self.imageURL = imageURL
        self.folderName = folderName
        self.coordinator = coordinator
        
        super.init(coordinator: coordinator)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadImage()
        setupView()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        saveNavBarSettings()
        setupNavBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        returnNavBarSettings()
    }
    
    // MARK: View setup
    private func returnNavBarSettings() {
        navigationController?.navigationBar.titleTextAttributes = navigationBarTitleTextAttributes
        
        if let navigationBarBarStyle = navigationBarBarStyle {
            navigationController?.navigationBar.barStyle = navigationBarBarStyle
        }
    }
    
    private func saveNavBarSettings() {
        navigationBarTitleTextAttributes = navigationController?.navigationBar.titleTextAttributes
        navigationBarBarStyle = navigationController?.navigationBar.barStyle
    }
    
    private func setupNavBar() {
        title = folderName
        navigationItem.leftBarButtonItems = nil
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.barStyle = .black
    }
    
    func setupView() {
        view.backgroundColor = .black
        
        buttonStackView.addArrangedSubview(againButton)
        buttonStackView.addArrangedSubview(nextPhotoButton)
        buttonStackView.addArrangedSubview(continueButton)
        
        view.addSubview(buttonStackView)
        buttonStackView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(10)
            make.leading.trailing.equalToSuperview().inset(5)
            make.height.equalTo(70)
        }
        
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.bottom.equalTo(buttonStackView.snp.top)
            make.top.leading.trailing.equalToSuperview()
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
    
    @objc func retake() {
        coordinator.createNewPhoto()
    }
    
    @objc func approved() {
        if let image = image {
            coordinator.photoApproved(image: image, fromGallery: false)
        } else {
            print("Image could not be approved")
        }
    }
     
    // MARK: Lazy instance part
    private lazy var imageView = UIImageView(image: image)
    
    private lazy var buttonStackView: UIStackView = {
        let buttonStackView = UIStackView()
        buttonStackView.alignment = .center
        buttonStackView.distribution = .fillEqually
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 10
        return buttonStackView
    }()
    
    private lazy var againButton: UIButton = {
        let againButton = UIButton()
        againButton.setTitle("newDocumentPhotos.againButton.title".localized, for: .normal)
        againButton.addTarget(self, action: #selector(retake), for: .touchUpInside)
        againButton.titleLabel?.font = .footnote
        againButton.titleLabel?.textColor = .white
        return againButton
    }()
    
    private lazy var nextPhotoButton: UIButton = {
        let nextPhotoButton = UIButton()
        nextPhotoButton.setTitle("newDocumentPhotos.nextPhoto.title".localized, for: .normal)
        nextPhotoButton.addTarget(self, action: #selector(retake), for: .touchUpInside)
        nextPhotoButton.titleLabel?.font = .footnote
        nextPhotoButton.titleLabel?.textColor = .white
        nextPhotoButton.layer.cornerRadius = 8
        nextPhotoButton.layer.borderWidth = 1
        nextPhotoButton.layer.borderColor = UIColor.white.cgColor
        nextPhotoButton.backgroundColor = .black
        return nextPhotoButton
    }()
    
    private lazy var continueButton: UIButton = {
        let continueButton = UIButton()
        continueButton.setTitle("newDocumentPhotos.continue.title".localized, for: .normal)
        continueButton.addTarget(self, action: #selector(approved), for: .touchUpInside)
        continueButton.titleLabel?.font = .footnote
        continueButton.titleLabel?.textColor = .white
        continueButton.layer.cornerRadius = 6
        continueButton.backgroundColor = .blue
        return continueButton
    }()
}
