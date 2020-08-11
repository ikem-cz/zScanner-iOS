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
    
    enum State {
        case normal
        case cropping
        case coloring
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        imageView.viewWillAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        imageView.viewWillDisappear()
    }

    // MARK: Instance part
    private var state: State = .normal {
        didSet {
            let buttons: [UIView]
            toolbar.arrangedSubviews.forEach({ $0.removeFromSuperview() })
            buttonStackView.arrangedSubviews.forEach({
                ($0 as? UIButton)?.isEnabled = false
                $0.alpha = 0.5
            })
            
            switch state {
            case .normal:
                buttons = [colorButton, cropButton, rotateButton]
                buttonStackView.arrangedSubviews.forEach({
                    ($0 as? UIButton)?.isEnabled = true
                    $0.alpha = 1
                })
                
            case .cropping:
                buttons = [removeCropButton, confirmCropButton]
                
            case .coloring:
                buttons = [noFilterButton, grayscaleFilterButton, monoFilterButton, confirmFilterButton]
            }
            
            buttons.forEach({ toolbar.addArrangedSubview($0) })
        }
    }
    
    // MARK: View setup
    override func setupView() {
        super.setupView()
        
        view.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(safeArea)
            make.bottom.equalTo(buttonStackView.snp.top)
        }
        
        view.addSubview(toolbar)
        toolbar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(imageView)
            make.height.equalTo(44)
        }
        
        let background = GradientView()
        background.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        toolbar.addSubview(background)
        background.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        state = .normal
    }
    
    // MARK: Helpers
    @objc private func showColoring() {
        state = .coloring
    }
    
    @objc private func hideColoring() {
        state = .normal
    }
    
    @objc private func removeFilter() {
        imageView.setFilter(.full)
    }
    
    @objc private func grayscaleFilter() {
        imageView.setFilter(.grayscale)
    }
    
    @objc private func monoFilter() {
        imageView.setFilter(.mono)
    }
    
    @objc private func rotateImage() {
        media.rotateImage()
        media.saveCrop()
        imageView.setMode(imageView.mode)
    }
    
    @objc private func cropImage() {
        media.cropRectangle = media.cropRectangle ?? .default
        imageView.setMode(.edit)
        state = .cropping
    }
    
    @objc private func saveCrop() {
        media.saveCrop()
        imageView.setMode(.preview)
        state = .normal
    }
    
    @objc private func removeCrop() {
        media.cropRectangle = nil
        imageView.setMode(.preview)
        state = .normal
    }
    
    // MARK: Lazy instance part
    private lazy var imageView = CroppingImageView(media: media)!
    
    private lazy var toolbar: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.tintColor = .white
        return stackView
    }()
    
    private lazy var colorButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "circle.lefthalf.fill"), for: .normal)
        button.addTarget(self, action: #selector(showColoring), for: .touchUpInside)
        return button
    }()
    
    private lazy var noFilterButton: UIButton = {
        let button = UIButton()
        button.setTitle("Barva", for: .normal)
        button.addTarget(self, action: #selector(removeFilter), for: .touchUpInside)
        return button
    }()
    
    private lazy var grayscaleFilterButton: UIButton = {
        let button = UIButton()
        button.setTitle("St. šedi", for: .normal)
        button.addTarget(self, action: #selector(grayscaleFilter), for: .touchUpInside)
        return button
    }()
    
    private lazy var monoFilterButton: UIButton = {
        let button = UIButton()
        button.setTitle("Černobíle", for: .normal)
        button.addTarget(self, action: #selector(monoFilter), for: .touchUpInside)
        return button
    }()
    
    private lazy var confirmFilterButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "checkmark.circle"), for: .normal)
        button.addTarget(self, action: #selector(hideColoring), for: .touchUpInside)
        return button
    }()
    
    private lazy var cropButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "skew"), for: .normal)
        button.addTarget(self, action: #selector(cropImage), for: .touchUpInside)
        return button
    }()
    
    private lazy var rotateButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "rotate.right"), for: .normal)
        button.addTarget(self, action: #selector(rotateImage), for: .touchUpInside)
        return button
    }()
    
    private lazy var confirmCropButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "checkmark.circle"), for: .normal)
        button.addTarget(self, action: #selector(saveCrop), for: .touchUpInside)
        return button
    }()
    
    private lazy var removeCropButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "trash"), for: .normal)
        button.addTarget(self, action: #selector(removeCrop), for: .touchUpInside)
        return button
    }()
}


