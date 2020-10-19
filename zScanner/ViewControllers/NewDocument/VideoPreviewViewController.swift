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

class VideoPreviewViewController: MediaPreviewViewController {

    // MARK: Instance part
    private let videoViewController = AVPlayerViewController()
    
    // MARK: View setup
    override func setupView() {
        super.setupView()
        
        view.addSubview(videoViewController.view)
        videoViewController.view.snp.makeConstraints { make in
            make.top.width.equalTo(safeArea)
            make.bottom.equalTo(buttonStackView.snp.top)
        }
    }
    
    // MARK: Helpers
    override func viewDidLoad() {
        super.viewDidLoad()

        let player = AVPlayer(url: media.url)
        videoViewController.player = player
        videoViewController.view.frame = .zero
    }
    
    override func stopPlayingVideo() {
        videoViewController.player?.pause()
    }
}
