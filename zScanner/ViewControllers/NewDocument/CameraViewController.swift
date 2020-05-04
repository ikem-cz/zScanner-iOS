//
//  CameraViewController.swift
//  zScanner
//
//  Created by Jan Provazník on 01/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import AVFoundation
import UPCarouselFlowLayout

class CameraViewController: UIViewController {

    enum mediaType {
        case photo
        case video
        case scan
        case audio
        
        var description: String {
            switch self {
            case .photo: return "newDocumentPhotos.mediaType.photo".localized
            case .video: return "newDocumentPhotos.mediaType.video".localized
            case .scan: return "newDocumentPhotos.mediaType.scan".localized
            case .audio: return "newDocumentPhotos.mediaType.audio".localized
            }
        }
    }
    
    private var captureSession: AVCaptureSession!
    private var stillImageOutput: AVCapturePhotoOutput!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private let viewModel: NewDocumentPhotosViewModel
    private let mediaSourceTypes = [
        mediaType.photo,
        mediaType.video
    ]
    
    fileprivate var pageSize: CGSize {
        let layout = self.mediaSourceTypeCollectionView.collectionViewLayout as! UPCarouselFlowLayout
        var pageSize = layout.itemSize
        pageSize.width += layout.minimumLineSpacing
        return pageSize
    }
    
    fileprivate var currentMode: Int = 0 {
           didSet {
                print(mediaSourceTypes[currentMode].description)
           }
       }
    
    init(viewModel: NewDocumentPhotosViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCaptureSession()
        setupView()
    }
    
    func setupView() {
        view.addSubview(captureButton)
        captureButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(8)
            make.height.width.equalTo(70)
        }
        
        captureButton.addSubview(middleCaptureButton)
        middleCaptureButton.snp.makeConstraints { make in
            make.centerX.centerY.equalTo(captureButton)
            make.height.width.equalTo(60)
        }
        
        view.addSubview(mediaSourceTypeCollectionView)
        mediaSourceTypeCollectionView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(captureButton.snp.top).inset(-10)
            make.height.equalTo(40)
            make.width.equalToSuperview()
        }
        
        view.addSubview(cameraView)
        cameraView.snp.makeConstraints { make in
            make.top.width.equalToSuperview()
            make.bottom.equalTo(mediaSourceTypeCollectionView.snp.top)
        }
    }

    func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        
        guard let backCamera = AVCaptureDevice.default(for: AVMediaType.video) else {
                print("Unable to access back camera!")
                return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            stillImageOutput = AVCapturePhotoOutput()

            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            }
        } catch let error  {
            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
        }
    }
    
    private lazy var cameraView = CameraView(frame: .zero, videoPreviewLayer: self.videoPreviewLayer, captureSession: self.captureSession)
    
    private lazy var mediaSourceTypeCollectionView: UICollectionView = {
        let layout = UPCarouselFlowLayout()
        layout.itemSize = CGSize(width: 30, height: 20)
        layout.scrollDirection = .horizontal
        let mediaSourceTypeCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        mediaSourceTypeCollectionView.register(MediaTypeCollectionViewCell.self, forCellWithReuseIdentifier: "CollectionCell")
        mediaSourceTypeCollectionView.delegate = self
        mediaSourceTypeCollectionView.dataSource = self
        return mediaSourceTypeCollectionView
    }()
    
    private lazy var captureButton: UIButton = {
        let captureButton = UIButton()
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 35
        captureButton.clipsToBounds = true
        return captureButton
    }()
    
    private lazy var middleCaptureButton: UIButton = {
        let middleCaptureButton = UIButton()
        middleCaptureButton.layer.cornerRadius = 30
        middleCaptureButton.layer.borderWidth = 2
        middleCaptureButton.layer.borderColor = UIColor.black.cgColor
        middleCaptureButton.backgroundColor = .white
        middleCaptureButton.clipsToBounds = true
        middleCaptureButton.addTarget(self, action: #selector(takePicture), for: .touchUpInside)
        return middleCaptureButton
    }()
    
    func animateCaptureButton(toValue: CGFloat, duration: Double) {
        let animation:CABasicAnimation = CABasicAnimation(keyPath: "borderWidth")
        animation.fromValue = middleCaptureButton.layer.borderWidth
        animation.toValue = toValue
        animation.duration = duration
        middleCaptureButton.layer.add(animation, forKey: "Width")
        middleCaptureButton.layer.borderWidth = toValue
    }
    
    @objc func takePicture() {
        animateCaptureButton(toValue: 4, duration: 0.3)
        animateCaptureButton(toValue: 2, duration: 0.3)
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        stillImageOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation(), let pickedImage = UIImage(data: imageData) {
            viewModel.addImage(pickedImage, fromGallery: false)
        }
        self.dismiss(animated: true, completion: nil)
    }
}

extension CameraViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaSourceTypes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = mediaSourceTypeCollectionView.dequeueReusableCell(withReuseIdentifier: "CollectionCell", for: indexPath) as! MediaTypeCollectionViewCell
        cell.setup(with: mediaSourceTypes[indexPath.row].description)
        return cell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let layout = self.mediaSourceTypeCollectionView.collectionViewLayout as! UPCarouselFlowLayout
        let pageSide = (layout.scrollDirection == .horizontal) ? self.pageSize.width : self.pageSize.height
        let offset = (layout.scrollDirection == .horizontal) ? scrollView.contentOffset.x : scrollView.contentOffset.y
        currentMode = Int(floor((offset - pageSide / 2) / pageSide) + 1)
    }
}
