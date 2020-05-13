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

class VideoPreviewViewController: MediumPreviewViewController {

    // MARK: Instance part
    private let videoViewController = AVPlayerViewController()
    
    // MARK: Lifecycle
    init(videoURL: URL, viewModel: NewDocumentMediaViewModel, coordinator: MediumPreviewCoordinator) {
        
        super.init(viewModel: viewModel, mediumType: .video, mediumURL: videoURL, folderName: viewModel.folderName, coordinator: coordinator)
    }
    
    // MARK: View setup
    override func setupView() {
        view.addSubview(videoViewController.view)
        videoViewController.view.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            make.bottom.equalTo(buttonStackView.snp.top)
        }
    }
    
    // MARK: Helpers
    override func loadMedium() {
        let player = AVPlayer(url: mediumURL)
        videoViewController.player = player
        videoViewController.view.frame = .zero
    }
}