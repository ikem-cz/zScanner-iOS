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
import MobileCoreServices

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
    private var photoOutput: AVCapturePhotoOutput!
    private var videoOutput: AVCaptureMovieFileOutput!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private let viewModel: NewDocumentPhotosViewModel
    private let mediaSourceTypes = [
        mediaType.photo,
        mediaType.video
    ]
    
    private var isRecording: Bool
    
    fileprivate var pageSize: CGSize {
        let layout = self.mediaSourceTypeCollectionView.collectionViewLayout as! UPCarouselFlowLayout
        var pageSize = layout.itemSize
        pageSize.width += layout.minimumLineSpacing
        return pageSize
    }
    
    fileprivate var currentMode: mediaType = .photo {
        didSet {
            switch currentMode {
            case .photo:
                middleCaptureButton.isHidden = false
                middleRecordButton.isHidden = true
            case .video:
                middleCaptureButton.isHidden = true
                middleRecordButton.isHidden = false
            case .scan:
                middleCaptureButton.isHidden = false
                middleCaptureButton.isHidden = true
            default:
                print(captureButton.description, ": Not yet done")
            }
        }
    }
    
    init(viewModel: NewDocumentPhotosViewModel) {
        self.viewModel = viewModel
        self.isRecording = false
        
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
        
        captureButton.addSubview(middleRecordButton)
        middleRecordButton.snp.makeConstraints { make in
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
        
        view.addSubview(galleryButton)
        galleryButton.snp.makeConstraints { make in
            make.bottom.left.equalToSuperview().inset(8)
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
            photoOutput = AVCapturePhotoOutput()
            videoOutput = AVCaptureMovieFileOutput()
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            if captureSession.canAddInput(input) && captureSession.canAddOutput(photoOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(photoOutput)
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
    
    private lazy var middleRecordButton: UIButton = {
        let middleRecordButton = UIButton()
        middleRecordButton.layer.cornerRadius = 30
        middleRecordButton.layer.borderWidth = 2
        middleRecordButton.layer.borderColor = UIColor.black.cgColor
        middleRecordButton.backgroundColor = .red
        middleRecordButton.clipsToBounds = true
        middleRecordButton.isHidden = true
        middleRecordButton.addTarget(self, action: #selector(recordVideo), for: .touchUpInside)
        return middleRecordButton
    }()
    
    private lazy var galleryButton: GalleryButton = {
        let galleryButton = GalleryButton()
        let tap = UITapGestureRecognizer(target: self, action: #selector(openGallery))
        galleryButton.addGestureRecognizer(tap)
        galleryButton.isUserInteractionEnabled = true
        return galleryButton
    }()
    
    func animateCaptureButton(toValue: CGFloat, duration: Double) {
        let animation:CABasicAnimation = CABasicAnimation(keyPath: "borderWidth")
        animation.fromValue = middleCaptureButton.layer.borderWidth
        animation.toValue = toValue
        animation.duration = duration
        middleCaptureButton.layer.add(animation, forKey: "Width")
        middleCaptureButton.layer.borderWidth = toValue
    }
    
    func animateRecordButton(duration: Double) {
        UIView.animate(withDuration: duration,
        animations: {
            self.middleRecordButton.transform = self.isRecording ? CGAffineTransform(scaleX: 0.8, y: 0.8) : CGAffineTransform.identity
            let animation = CABasicAnimation(keyPath: "cornerRadius")
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
            animation.fillMode = CAMediaTimingFillMode.forwards
            animation.isRemovedOnCompletion = false
            animation.fromValue = self.middleRecordButton.layer.cornerRadius
            animation.toValue = self.isRecording ? 10 : self.middleRecordButton.bounds.width/2
            animation.duration = 1
            self.middleRecordButton.layer.add(animation, forKey: "cornerRadius")
        }, completion: nil )
    }
    
    @objc func takePicture() {
        animateCaptureButton(toValue: 4, duration: 0.3)
        animateCaptureButton(toValue: 2, duration: 0.3)
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc func openGallery() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.mediaTypes = currentMode == .photo ? [kUTTypeImage as String] : [kUTTypeMovie as String]
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    @objc func recordVideo() {
        guard let captureSession = self.captureSession, captureSession.isRunning else { return }

        if isRecording {
            videoOutput.stopRecording()
            isRecording = false
        } else {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            #warning("How to save it?")
            let fileUrl = paths[0].appendingPathComponent("output.mp4")
            try? FileManager.default.removeItem(at: fileUrl)
            videoOutput!.startRecording(to: fileUrl, recordingDelegate: self)
            isRecording = true
        }
        animateRecordButton(duration: 0.6)
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

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print(error)
        } else {
            #warning("What to do?")
            print("Video was recorded")
        }
    }
}

extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            viewModel.addImage(pickedImage, fromGallery: picker.sourceType == .photoLibrary)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
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
        let index = Int(floor((offset - pageSide / 2) / pageSide) + 1)
        currentMode = mediaSourceTypes[index]
    }
}
