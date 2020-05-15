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
import RxSwift

protocol CameraCoordinator: BaseCoordinator {
    func mediaCreated(_ type: MediaType, url: URL)
}

// MARK: -
class CameraViewController: BaseViewController {

    // MARK: Instance part
    private var captureSession: AVCaptureSession!
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureMovieFileOutput()
    private let videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
    private let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    private unowned let coordinator: CameraCoordinator
    private let viewModel: CameraViewModel
    let disposeBag = DisposeBag()
    
    private var isRecording: Bool = false
    private var isFlashing: Bool = false
    
    override var rightBarButtonItems: [UIBarButtonItem] {
        return [flashButton]
    }
    
    // Used to find current mode in collection view
    fileprivate var pageSize: CGSize {
        let layout = self.mediaSourceTypeCollectionView.collectionViewLayout as! UPCarouselFlowLayout
        var pageSize = layout.itemSize
        pageSize.width += layout.minimumLineSpacing
        return pageSize
    }
    
    init(viewModel: CameraViewModel, coordinator: CameraCoordinator) {
        self.viewModel = viewModel
        self.coordinator = coordinator
        
        super.init(coordinator: coordinator, theme: .dark)
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCaptureSession()
        setupView()
        setupBindings()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        captureSession.stopRunning()
    }
    
    // MARK: View setup
    private func setupBindings() {
        viewModel.currentMode
            .subscribe(onNext: { [unowned self] mode in
                switch mode {
                case .photo:
                    self.preparePhotoSession()
                    self.middleCaptureButton.isHidden = false
                    self.middleRecordButton.isHidden = true
                case .video:
                    self.prepareVideoSession()
                    self.middleCaptureButton.isHidden = true
                    self.middleRecordButton.isHidden = false
                case .scan:
                    self.middleCaptureButton.isHidden = false
                    self.middleCaptureButton.isHidden = true
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setupView() {
        view.backgroundColor = .clear
        title = viewModel.folderName
        
        view.addSubview(captureButton)
        captureButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(safeArea).inset(8)
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
            make.top.equalTo(safeArea)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(mediaSourceTypeCollectionView.snp.top)
        }
        
        view.addSubview(swipeMediaTypeView)
        swipeMediaTypeView.snp.makeConstraints { make in
            make.top.equalTo(safeArea)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(mediaSourceTypeCollectionView.snp.top)
        }
        
        view.addSubview(galleryButton)
        galleryButton.snp.makeConstraints { make in
            make.bottom.left.equalTo(safeArea).inset(8)
        }
        
        view.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(safeArea).inset(5)
            make.trailing.leading.centerX.equalToSuperview()
        }
    }
    
    // MARK: Setup media session
    func preparePhotoSession() {
        guard let videoDevice = videoDevice else { return }
        
        if captureSession.isRunning { captureSession.stopRunning() }
        
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
            print("Error Unable to initialize back camera:  \(error.localizedDescription).")
        }
    }
    
    func prepareVideoSession() {
        guard let videoDevice = videoDevice, let audioDevice = audioDevice else { return }
        
        if captureSession.isRunning { captureSession.stopRunning() }
        
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
            print("Error Unable to initialize video with audio:  \(error.localizedDescription).")
        }
    }

    func setupCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    }

    // MARK: Helpers
    @objc func mediaTypeSwipeHandler(gesture: UISwipeGestureRecognizer) {
        guard let index = viewModel.mediaSourceTypes.firstIndex(of: viewModel.currentMode.value) else { return }
        let lastIndex = viewModel.mediaSourceTypes.count - 1
        if gesture.direction == .left {
            if index < lastIndex {
                let newIndex = index + 1
                viewModel.newModeSelected(with: viewModel.mediaSourceTypes[newIndex])
                mediaSourceTypeCollectionView.selectItem(at: IndexPath(row: newIndex, section: 0), animated: true, scrollPosition: .centeredHorizontally)
            }
        } else if gesture.direction == .right {
            if index > 0 {
                let newIndex = index - 1
                viewModel.newModeSelected(with: viewModel.mediaSourceTypes[newIndex])
                mediaSourceTypeCollectionView.selectItem(at: IndexPath(row: newIndex, section: 0), animated: true, scrollPosition: .centeredHorizontally)
            }
        } else {
            print("Undefined swipe direction.")
        }
    }

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
                print("Torch could not be used.")
            }
        } else {
            print("Torch is not available.")
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
        UIView.animate(withDuration: duration) {
            // scale button
            self.middleRecordButton.transform = self.isRecording ? CGAffineTransform(scaleX: 0.8, y: 0.8) : CGAffineTransform.identity
            
            // change circle shape to square and vice versa
            let animation = CABasicAnimation(keyPath: "cornerRadius")
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
            animation.fillMode = CAMediaTimingFillMode.forwards
            animation.isRemovedOnCompletion = false
            animation.fromValue = self.middleRecordButton.layer.cornerRadius
            animation.toValue = self.isRecording ? 10 : self.middleRecordButton.bounds.width/2
            animation.duration = 1
            self.middleRecordButton.layer.add(animation, forKey: "cornerRadius")
        }
    }
    
    func takePictureFlash() {
        UIView.animate(withDuration: 0.1, animations: {
            self.swipeMediaTypeView.backgroundColor = .black
        }) { _ in
            self.swipeMediaTypeView.backgroundColor = .clear
        }
    }
    
    @objc func takePicture() {
        animateCaptureButton(toValue: 4, duration: 0.3)
        takePictureFlash()
        animateCaptureButton(toValue: 2, duration: 0.3)
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc func openGallery() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.mediaTypes = viewModel.currentMode.value == .photo ? [kUTTypeImage as String] : [kUTTypeMovie as String]
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    @objc func recordVideo() {
        guard let captureSession = self.captureSession, captureSession.isRunning else { return }
        if isRecording {
            videoOutput.stopRecording()
            isRecording = false
        } else {
            let fileURL = createMediaURL(suffix: ".mp4")
            videoOutput.maxRecordedDuration = CMTime(seconds: Config.maximumSecondsOfVideoRecording, preferredTimescale: 600)
            videoOutput.startRecording(to: fileURL, recordingDelegate: self)
            count()
            isRecording = true
        }
        animateRecordButton(duration: 0.6)
    }
    
    func createMediaURL(suffix: String) -> URL {
        let fileName = UUID().uuidString + suffix
        let fileURL = URL.init(documentsWith: fileName)
        return fileURL
    }
    
    func saveImage(withURL fileURL: URL, image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 1) else { return }
        
        do {
            try data.write(to: fileURL)
        } catch let error {
            print("error saving file with error", error)
        }
    }
    
    var timerSubscription: Disposable?
    
    func count() {
        let timer = Observable<Int>.interval(RxTimeInterval.milliseconds(100), scheduler: MainScheduler.instance)
        timerSubscription = timer
            .map { [weak self] in self?.stringFromTimeInterval(ms: $0) }
            .bind(to: timeLabel.rx.text)
    }
    
    func stringFromTimeInterval(ms: Int) -> String {
        return String(format: "%0.2d:%0.2d", arguments: [(ms / 600) % 600, (ms % 600 ) / 10])
    }
    
    // MARK: Lazy instance part
    private lazy var cameraView = CameraView(frame: .zero, videoPreviewLayer: self.videoPreviewLayer, captureSession: self.captureSession)
    
    private lazy var mediaSourceTypeCollectionView: UICollectionView = {
        let layout = UPCarouselFlowLayout()
        layout.itemSize = CGSize(width: 50, height: 20)
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
    
    private lazy var timeLabel: UILabel = {
        let timeLabel = UILabel()
        timeLabel.font = .headline
        timeLabel.textAlignment = .center
        timeLabel.textColor = .white
        return timeLabel
    }()
    
    private lazy var flashButton = UIBarButtonItem(image: UIImage(systemName: "bolt.fill"), style: .plain, target: self, action: #selector(toggleTorch))
}

// MARK: - AVCapturePhotoCaptureDelegate implementation
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        
        if let image = UIImage(data: imageData) {
            let fileURL = createMediaURL(suffix: ".jpg")
            saveImage(withURL: fileURL, image: image)
            coordinator.mediaCreated(.photo, url: fileURL)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate implementation
extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            let fileURL = createMediaURL(suffix: ".jpg")
            saveImage(withURL: fileURL, image: pickedImage)
            coordinator.mediaCreated(.photo, url: fileURL)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate implementation
extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        timerSubscription?.dispose()
        switch error {
        case .none:
            if isRecording {
                recordVideo()
            }
            coordinator.mediaCreated(.video, url: outputFileURL)
        case .some(let nsError as NSError) where (nsError.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool) == true:
            if isRecording {
                recordVideo()
            }
            coordinator.mediaCreated(.video, url: outputFileURL)
        default:
            // TODO: Handle this error
            print(error)
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource implementation
extension CameraViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.mediaSourceTypes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = mediaSourceTypeCollectionView.dequeueReusableCell(withReuseIdentifier: "CollectionCell", for: indexPath) as! MediaTypeCollectionViewCell
        let item = viewModel.mediaSourceTypes[indexPath.row]
        cell.setup(with: item)
        return cell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let layout = self.mediaSourceTypeCollectionView.collectionViewLayout as! UPCarouselFlowLayout
        let pageSide = (layout.scrollDirection == .horizontal) ? self.pageSize.width : self.pageSize.height
        let offset = (layout.scrollDirection == .horizontal) ? scrollView.contentOffset.x : scrollView.contentOffset.y
        let index = Int(floor((offset - pageSide / 2) / pageSide) + 1)
        viewModel.newModeSelected(with: viewModel.mediaSourceTypes[index])
    }
}
