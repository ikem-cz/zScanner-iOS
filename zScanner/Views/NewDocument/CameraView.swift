//
//  CameraView.swift
//  zScanner
//
//  Created by Jan Provazník on 01/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import AVFoundation

class CameraView: UIView {

    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var captureSession: AVCaptureSession!
    
    // MARK: Instance part
    init(frame: CGRect, videoPreviewLayer: AVCaptureVideoPreviewLayer, captureSession: AVCaptureSession) {
        self.videoPreviewLayer = videoPreviewLayer
        self.captureSession = captureSession
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lifecycle
    override func layoutSubviews() {
        super.layoutSubviews()
        
        videoPreviewLayer?.frame = bounds
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        captureSession.startRunning()
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        
        captureSession.stopRunning()
    }
    
    // MARK: Helpers
    func setupView() {
        videoPreviewLayer.videoGravity = .resizeAspect
        videoPreviewLayer.connection?.videoOrientation = .portrait
        layer.addSublayer(videoPreviewLayer)
    }
    
}
