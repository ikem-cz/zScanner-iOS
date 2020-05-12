//
//  VideoPreviewViewController.swift
//  zScanner
//
//  Created by Jan Provazník on 12/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

protocol VideoPreviewCoordinator: BaseCoordinator {
    func createNewVideo()
    func showVideosSelection()
}

class VideoPreviewViewController: BaseViewController {

    // MARK: Instance part
    private let videoURL: URL
    private let videoViewController = AVPlayerViewController()
    
    private unowned let coordinator: VideoPreviewCoordinator
    private let viewModel: NewDocumentMediaViewModel<URL>
    
    private var navigationBarTitleTextAttributes: [NSAttributedString.Key : Any]?
    private var navigationBarBarStyle: UIBarStyle? // Background-color of the navigation controller, which automatically adapts the color of the status bar (time, battery ..)
    override var navigationBarTintColor: UIColor? { .white } // Color of navigation controller items
    
    // MARK: Lifecycle
    init(videoURL: URL, viewModel: NewDocumentMediaViewModel<URL>, coordinator: VideoPreviewCoordinator) {
        self.videoURL = videoURL
        self.viewModel = viewModel
        self.coordinator = coordinator
        
        super.init(coordinator: coordinator)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        playVideo()
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
        title = viewModel.folderName
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
        
        view.addSubview(videoViewController.view)
        videoViewController.view.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            make.bottom.equalTo(buttonStackView.snp.top)
        }
    }
    
    // MARK: Helpers
    private func playVideo() {
        let player = AVPlayer(url: videoURL)
        videoViewController.player = player
        videoViewController.view.frame = CGRect(x: 0, y: 0, width: 100, height: 300)
    }
    
    @objc func retakePhoto() {
        coordinator.createNewVideo()
    }
    
    @objc func createAnotherPhoto() {
        viewModel.addMedia(videoURL, fromGallery: false)
        coordinator.createNewVideo()
    }
    
    @objc func showPhotosSelection() {
        viewModel.addMedia(videoURL, fromGallery: false)
        coordinator.showVideosSelection()
    }
    
    // MARK: Lazy instance part
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
        againButton.addTarget(self, action: #selector(retakePhoto), for: .touchUpInside)
        againButton.titleLabel?.font = .footnote
        againButton.titleLabel?.textColor = .white
        return againButton
    }()
    
    private lazy var nextPhotoButton: UIButton = {
        let nextPhotoButton = UIButton()
        nextPhotoButton.setTitle("newDocumentPhotos.nextPhoto.title".localized, for: .normal)
        nextPhotoButton.addTarget(self, action: #selector(createAnotherPhoto), for: .touchUpInside)
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
        continueButton.addTarget(self, action: #selector(showPhotosSelection), for: .touchUpInside)
        continueButton.titleLabel?.font = .footnote
        continueButton.titleLabel?.textColor = .white
        continueButton.layer.cornerRadius = 6
        continueButton.backgroundColor = .blue
        return continueButton
    }()
}
