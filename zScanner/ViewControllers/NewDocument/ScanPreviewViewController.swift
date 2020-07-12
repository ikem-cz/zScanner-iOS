//
//  ScanPreviewViewController.swift
//  zScanner
//
//  Created by Jan Provazník on 07/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import Vision

class ScanPreviewViewController: MediaPreviewViewController {    
    
    // MARK: View setup
    override func setupView() {
        view.addSubview(imageView)
        view.addSubview(modeSwich)
        
        modeSwich.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(safeArea).inset(8)
            make.height.equalTo(32)
        }
        
        imageView.snp.makeConstraints { make in
            make.top.equalTo(modeSwich.snp.bottom).offset(8)
            make.leading.trailing.equalTo(safeArea)
            make.bottom.equalTo(buttonStackView.snp.top)
        }
    }

    @objc private func switchMode(_ segmentedControl: UISegmentedControl) {
        let mode = modes[segmentedControl.selectedSegmentIndex]
        imageView.setMode(mode)
    }

    // MARK: Helpers
    private let modes = [CropMode.edit, .preview]
    
    // MARK: Lazy instance part
    private lazy var modeSwich: UISegmentedControl = {
        let modeSwitch = UISegmentedControl(items: modes.map({ $0.title }))
        modeSwitch.selectedSegmentIndex = 0
        modeSwitch.addTarget(self, action: #selector(switchMode(_:)), for: .valueChanged)
        modeSwitch.backgroundColor = .lightGray
        modeSwitch.selectedSegmentTintColor = .black
        modeSwitch.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .selected)
        return modeSwitch
    }()
    
    private lazy var imageView = CroppingImageView(media: media)!
}


