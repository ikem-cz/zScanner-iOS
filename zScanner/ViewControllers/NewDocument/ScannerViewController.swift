//
//  ScannerViewController.swift
//  zScanner
//
//  Created by Jakub Skořepa on 11/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import AVFoundation

protocol ScannerDelegate: class {
    func close()
}

// MARK: -
class ScannerViewController: UIViewController {
    
    // MARK: Instance part
    private unowned let delegate: ScannerDelegate
    private let viewModel: NewDocumentFolderViewModel
    
    init(viewModel: NewDocumentFolderViewModel, delegate: ScannerDelegate) {
        self.delegate = delegate
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lifecycle
    override func loadView() {
        super.loadView()
        
        setupView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "delete"), style: .plain, target: self, action: #selector(close))
        navigationItem.leftBarButtonItem?.tintColor = .white

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .clear
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(
                for: .video,
                completionHandler: { [weak self] enabled in
                    if !enabled {
                        DispatchQueue.main.async {
                            self?.failed()
                        }
                    }
                }
            )
        case .restricted, .denied:
            failed()
        default:
            break
        }
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            failed()
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .qr]
        } else {
            failed()
            return
        }
        
        view.layer.addSublayer(previewLayer)
        captureSession.startRunning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.layer.bounds
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: Helpers
    private lazy var captureSession = AVCaptureSession()
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview.frame = view.layer.bounds
        preview.videoGravity = .resizeAspectFill
        return preview
    }()
    
    private func failed() {
        let alert = UIAlertController(title: "newDocumentFolder.cameraFailed.title".localized, message: "newDocumentFolder.cameraFailed.message".localized, preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(
                title: "alert.cancelButton.title".localized,
                style: .cancel
            )
        )
        alert.addAction(
            UIAlertAction(
                title: "alert.settingsButton.title".localized,
                style: .default,
                handler: { _ in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }
            )
        )
        self.present(alert, animated: true)
    }
    
    func found(code: String) {
        viewModel.getFolder(with: code)
        delegate.close()
    }
    
    @objc private func close() {
        delegate.close()
    }
    
    private func setupView() {
        view.backgroundColor = UIColor.black
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate implementation
extension ScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        guard
            let metadataObject = metadataObjects.first,
            let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
            let stringValue = readableObject.stringValue
        else {
            failed()
            return
        }
        
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        found(code: stringValue)
    }
}

