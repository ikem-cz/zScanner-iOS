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

protocol CameraDelegate: BaseCoordinator {
    func getMediaURL(fileURL: URL)
}

class CameraViewController: UIViewController {

    enum MediaType {
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
        
        var index: Int {
            switch self {
            case .photo: return 0
            case .video: return 1
            case .scan: return 2
            case .audio: return 3
            }
        }
    }
    
    private var captureSession: AVCaptureSession!
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureMovieFileOutput()
    private let videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
    private let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private let mediaSourceTypes = [
        MediaType.photo,
        MediaType.video
    ]
    
    private let folderName: String
    private weak var delegate: CameraDelegate?
    
    private var isRecording: Bool = false
    private var isFlashing: Bool = false
    
    private var navigationBarTitleTextAttributes: [NSAttributedString.Key : Any]?
    private var navigationBarTintColor: UIColor?
    private var navigationBarBarStyle: UIBarStyle?
    
    fileprivate var pageSize: CGSize {
        let layout = self.mediaSourceTypeCollectionView.collectionViewLayout as! UPCarouselFlowLayout
        var pageSize = layout.itemSize
        pageSize.width += layout.minimumLineSpacing
        return pageSize
    }
    
    fileprivate var currentMode: MediaType = .photo {
        didSet {
            switch currentMode {
            case .photo:
                preparePhotoSession()
                middleCaptureButton.isHidden = false
                middleRecordButton.isHidden = true
            case .video:
                prepareVideoSession()
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
    
    init(folderName: String, delegate: CameraDelegate) {
        self.folderName = folderName
        self.delegate = delegate
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        saveNavBarSettings()
        setupNavBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        returnNavBarSettings()
    }
    
    private func returnNavBarSettings() {
        navigationController?.navigationBar.titleTextAttributes = navigationBarTitleTextAttributes
        navigationController?.navigationBar.tintColor = navigationBarTintColor
        
        if let navigationBarBarStyle = navigationBarBarStyle {
            navigationController?.navigationBar.barStyle = navigationBarBarStyle
        }
    }
    
    private func saveNavBarSettings() {
        navigationBarTitleTextAttributes = navigationController?.navigationBar.titleTextAttributes
        navigationBarTintColor = navigationController?.navigationBar.tintColor
        navigationBarBarStyle = navigationController?.navigationBar.barStyle
    }
    
    private func setupNavBar() {
        title = folderName
        navigationItem.backBarButtonItem?.title = "newDocumentPhotos.navigationController.backButton.title".localized
        navigationItem.rightBarButtonItems = [flashButton]
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.tintColor = .white // Color of navigation controller items
        navigationController?.navigationBar.barStyle = .black // Background-color of the navigation controller, which automatically adapts the color of the status bar (time, battery ..)
    }
    
    private func setupView() {
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
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(mediaSourceTypeCollectionView.snp.top)
        }
        
        view.addSubview(swipeMediaTypeView)
        swipeMediaTypeView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(mediaSourceTypeCollectionView.snp.top)
        }
        
        view.addSubview(galleryButton)
        galleryButton.snp.makeConstraints { make in
            make.bottom.left.equalToSuperview().inset(8)
        }
    }
    
    func preparePhotoSession() {
        guard let videoDevice = videoDevice else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: videoDevice)
            
            captureSession.beginConfiguration()
            captureSession.inputs.forEach { captureSession.removeInput($0) }
            captureSession.outputs.forEach { captureSession.removeOutput($0) }
            
            if captureSession.canAddInput(input) && captureSession.canAddOutput(photoOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(photoOutput)
            }
            
            captureSession.commitConfiguration()
            captureSession.startRunning()
        } catch(let error) {
            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
        }
    }
    
    func prepareVideoSession() {
        guard let videoDevice = videoDevice, let audioDevice = audioDevice else { return }
        
        do {
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            
            captureSession.beginConfiguration()
            captureSession.inputs.forEach { captureSession.removeInput($0) }
            captureSession.outputs.forEach { captureSession.removeOutput($0) }
            
            if captureSession.canAddInput(audioInput) && captureSession.canAddInput(videoInput) && captureSession.canAddOutput(videoOutput) {
                captureSession.addInput(videoInput)
                captureSession.addInput(audioInput)
                captureSession.addOutput(videoOutput)
            }
            
            captureSession.commitConfiguration()
            captureSession.startRunning()
        } catch(let error) {
            print("Error Unable to initialize video with audio:  \(error.localizedDescription)")
        }
    }

    func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        
        // TODO: Call it later after currentMode is set up
        preparePhotoSession()
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
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
    
    private lazy var swipeMediaTypeView: UIView = {
        let swipeMediaTypeView = UIView()
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(mediaTypeSwipeHandler(gesture:)))
        swipeLeft.direction = .left
        swipeMediaTypeView.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(mediaTypeSwipeHandler(gesture:)))
        swipeRight.direction = .right
        swipeMediaTypeView.addGestureRecognizer(swipeRight)
        swipeMediaTypeView.isUserInteractionEnabled = true
        return swipeMediaTypeView
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
    
    @objc func mediaTypeSwipeHandler(gesture: UISwipeGestureRecognizer) {
        let lastIndex = mediaSourceTypes.count - 1
        if gesture.direction == .left {
            if currentMode.index < lastIndex {
                let newIndex = currentMode.index + 1
                currentMode = mediaSourceTypes[newIndex]
                mediaSourceTypeCollectionView.selectItem(at: IndexPath(row: newIndex, section: 0), animated: true, scrollPosition: .centeredHorizontally)
            }
        } else if gesture.direction == .right {
            if currentMode.index > 0 {
                let newIndex = currentMode.index - 1
                currentMode = mediaSourceTypes[newIndex]
                mediaSourceTypeCollectionView.selectItem(at: IndexPath(row: newIndex, section: 0), animated: true, scrollPosition: .centeredHorizontally)
            }
        } else {
            print("Undefined swipe direction")
        }
    }
    
    private lazy var flashButton = UIBarButtonItem(image: UIImage(systemName: "bolt.fill"), style: .plain, target: self, action: #selector(toggleTorch))

    @objc func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }

        if device.hasTorch {
            do {
                try device.lockForConfiguration()

                if isFlashing {
                    device.torchMode = .off
                    isFlashing = false
                    flashButton.image = UIImage(systemName: "bolt.fill")
                } else {
                    device.torchMode = .on
                    isFlashing = true
                    flashButton.image = UIImage(systemName: "bolt.slash.fill")
                }

                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    
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
            let fileName = UUID().uuidString + ".mp4"
            let fileURL = URL.init(documentsWith: fileName)
            videoOutput.startRecording(to: fileURL, recordingDelegate: self)
            isRecording = true
        }
        animateRecordButton(duration: 0.6)
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let delegate = delegate {
            let fileName = UUID().uuidString + ".jpg"
            let fileURL = URL.init(documentsWith: fileName)
            delegate.getMediaURL(fileURL: fileURL)
        } else {
            print("Unable to find CameraDelegate")
        }
        
        self.dismiss(animated: true, completion: nil)
    }
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print(error)
        } else {
            if let delegate = delegate {
                let fileName = UUID().uuidString + ".mp4"
                let fileURL = URL.init(documentsWith: fileName)
                delegate.getMediaURL(fileURL: fileURL)
            } else {
                print("Unable to find CameraDelegate")
            }
        }
    }
}

extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let delegate = delegate {
            let fileName = UUID().uuidString + ".jpg"
            let fileURL = URL.init(documentsWith: fileName)
            delegate.getMediaURL(fileURL: fileURL)
        } else {
            print("Unable to find CameraDelegate")
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
