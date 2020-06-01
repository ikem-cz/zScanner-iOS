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
import Vision
import SnapKit

protocol CameraCoordinator: BaseCoordinator {
    func mediaCreated(_ media: Media)
}

// MARK: -
class CameraViewController: BaseViewController {

    // MARK: Instance part
    private var captureSession: AVCaptureSession!
    private let photoOutput = AVCapturePhotoOutput()
    private let scanOutput = AVCaptureVideoDataOutput()
    private let videoOutput = AVCaptureMovieFileOutput()
    private let videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
    private let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    private unowned let coordinator: CameraCoordinator
    private let viewModel: CameraViewModel
    let disposeBag = DisposeBag()
    
    private var isRecording: Bool = false
    private var isFlashing: Bool = false {
        didSet {
            flashMode = isFlashing ? .on : .off
        }
    }
     
    private var flashMode: AVCaptureDevice.FlashMode = .off
    
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
        setupVision()
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
                    self.prepareScanSession()
                    self.middleCaptureButton.isHidden = false
                    self.middleRecordButton.isHidden = true
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: Setup media session
    func setupCaptureSession() {
        captureSession = AVCaptureSession()
        
        // Add temporary input to setup preview constraints
        if let videoDevice = videoDevice, let input = try? AVCaptureDeviceInput(device: videoDevice), captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    }
    
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
    
    func prepareScanSession() {
        guard let videoDevice = videoDevice else { return }
        
        if captureSession.isRunning { captureSession.stopRunning() }
        
        do {
            let input = try AVCaptureDeviceInput(device: videoDevice)
            
            captureSession.beginConfiguration()
            captureSession.inputs.forEach { captureSession.removeInput($0) }
            captureSession.outputs.forEach { captureSession.removeOutput($0) }
            
            if captureSession.canAddInput(input) && captureSession.canAddOutput(photoOutput) && captureSession.canAddOutput(scanOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(photoOutput)
                captureSession.addOutput(scanOutput)
                scanOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "queue"))
            }
            
            captureSession.commitConfiguration()
            captureSession.startRunning()
        } catch(let error) {
            print("Error Unable to initialize back camera:  \(error.localizedDescription).")
        }
    }
    
    private var requests = [VNRequest]()

    func setupVision() {
        let rectangleDetectionRequest = VNDetectRectanglesRequest(completionHandler: handleRectangles)
        rectangleDetectionRequest.minimumSize = 0.2
        rectangleDetectionRequest.maximumObservations = 20
        self.requests = [rectangleDetectionRequest]
    }
    
    func handleRectangles(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            if let results = request.results as? [VNObservation] {
                self.drawVisionRequestResults(results)
            }
        }
    }

    private var rectangleLayer: CAShapeLayer?
    private var lastResult: VNRectangleObservation?
    
    func drawVisionRequestResults(_ results: [VNObservation]) {
        guard let result = results.first as? VNRectangleObservation else { return }
        
        if let layer = self.rectangleLayer {
            layer.removeFromSuperlayer()
            self.rectangleLayer = nil
        }
        
        self.lastResult = result
        let points = [result.topLeft, result.topRight, result.bottomRight, result.bottomLeft]
        let convertedPoints = points.map { self.convertFromCamera($0) }
        self.rectangleLayer = self.drawBoundingBox(convertedPoints, color: #colorLiteral(red: 0.3328347607, green: 0.236689759, blue: 1, alpha: 1))
        self.cameraView.layer.addSublayer(self.rectangleLayer!)
    }
    
    private func drawBoundingBox(_ points: [CGPoint], color: CGColor) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.fillColor = #colorLiteral(red: 0.4506933627, green: 0.5190293554, blue: 0.9686274529, alpha: 0.2050513699)
        layer.strokeColor = color
        layer.lineWidth = 2
        let path = UIBezierPath()
        path.move(to: points.last!)
        points.forEach { point in
            path.addLine(to: point)
        }
        layer.path = path.cgPath
        return layer
    }
    
    func convertFromCamera(_ point: CGPoint) -> CGPoint {
        let orientation = UIApplication.shared.windows.first!.windowScene!.interfaceOrientation
        let rect = cameraView.frame
        
        var x: CGFloat = point.x
        var y: CGFloat = point.y
        
        switch orientation {
        case .portrait, .unknown:
            x = point.y
            y = point.x
        case .landscapeLeft:
            x = 1 - point.x
            y = point.y
        case .landscapeRight:
            x = point.x
            y = 1 - point.y
        case .portraitUpsideDown:
            x = 1 - point.y
            y = 1 - point.x
        @unknown default:
            break
        }
        return CGPoint(x: x * rect.width + rect.minX, y: y * rect.height + rect.minY)
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
                
                isFlashing.toggle()
                flashButton.image = isFlashing ? UIImage(systemName: "bolt.fill") : UIImage(systemName: "bolt.slash.fill")

                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used.")
            }
        } else {
            print("Torch is not available.")
        }
    }
    
    private func setupView() {
        view.backgroundColor = .black
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
        
        let cameraViewContainer = UIView()
        view.addSubview(cameraViewContainer)
        cameraViewContainer.snp.makeConstraints { make in
            make.top.equalTo(safeArea)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(mediaSourceTypeCollectionView.snp.top)
        }
        
        let previewDimensions = CMVideoFormatDescriptionGetDimensions((captureSession.inputs.first as! AVCaptureDeviceInput).device.activeFormat.formatDescription)
        let videoAspect = Double(previewDimensions.width)/Double(previewDimensions.height)
        cameraViewContainer.addSubview(cameraView)
        cameraView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.left.greaterThanOrEqualToSuperview()
            make.top.left.equalToSuperview().priority(500)
            make.height.equalTo(cameraView.snp.width).multipliedBy(videoAspect)
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
    
    private func getSettings(camera: AVCaptureDevice, flashMode: AVCaptureDevice.FlashMode) -> AVCapturePhotoSettings {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])

        if camera.hasFlash {
            settings.flashMode = flashMode
        }
        
        return settings
    }
    
    @objc func takePicture() {
        animateCaptureButton(toValue: 4, duration: 0.3)
        takePictureFlash()
        animateCaptureButton(toValue: 2, duration: 0.3)
        let settings = getSettings(camera: videoDevice!, flashMode: flashMode)
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc func openGallery() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.mediaTypes = viewModel.currentMode.value == .photo ? [kUTTypeImage as String] : [kUTTypeMovie as String]
        picker.sourceType = .photoLibrary
        picker.videoMaximumDuration = Config.maximumSecondsOfVideoRecording
        picker.allowsEditing = viewModel.currentMode.value == .video ? true : false
        present(picker, animated: true, completion: nil)
    }
    
    @objc func recordVideo() {
        guard let captureSession = self.captureSession, captureSession.isRunning else { return }
        if isRecording {
            videoOutput.stopRecording()
            isRecording = false
            animateRecordButton(duration: 0.6)
        } else {
            viewModel.saveVideo(fromGallery: false) { isSaved in
                guard isSaved else { return }
                
                DispatchQueue.main.async {
                    self.videoOutput.maxRecordedDuration = CMTime(seconds: Config.maximumSecondsOfVideoRecording, preferredTimescale: 600)
                    self.videoOutput.startRecording(to: self.viewModel.media!.url, recordingDelegate: self)
                    self.count()
                    self.isRecording = true
                    self.animateRecordButton(duration: 0.6)
                }
            }
        }
        
    }
    
    var timerSubscription: Disposable?
    
    func count() {
        let timer = Observable<Int>.interval(RxTimeInterval.milliseconds(100), scheduler: MainScheduler.instance)
        timerSubscription = timer
            .map { [weak self] in
                self?.stringFromTimeInterval(ms: $0)
            }
            .bind(to: timeLabel.rx.text)
    }
    
    func stringFromTimeInterval(ms: Int) -> String {
        return String(
            format: "%0.2d:%0.2d",
            arguments: [(ms / 600) % 600, (ms % 600 ) / 10]
        )
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
    
    private lazy var flashButton = UIBarButtonItem(image: UIImage(systemName: "bolt.slash.fill"), style: .plain, target: self, action: #selector(toggleTorch))
}

// MARK: - AVCapturePhotoCaptureDelegate implementation
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        
        if let image = UIImage(data: imageData) {
            if viewModel.currentMode.value == .scan {
                if let rectangle = lastResult {
                    viewModel.saveScan(image: image, rectangle: rectangle, fromGallery: false)
                    coordinator.mediaCreated(viewModel.media!)
                } else {
                    print("No rectangle detected")
                }
            } else {
                viewModel.saveImage(image: image, fromGallery: false)
                coordinator.mediaCreated(viewModel.media!)
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate implementation
extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            viewModel.saveImage(image: pickedImage, fromGallery: true)
            coordinator.mediaCreated(viewModel.media!)
        }
        if let videoURL = info[.mediaURL] as? URL {
            viewModel.saveVideo(fromGallery: true, url: videoURL) { isSaved in
                guard isSaved else { return }
                
                DispatchQueue.main.async {
                    self.coordinator.mediaCreated(self.viewModel.media!)
                }
            }
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
            coordinator.mediaCreated(viewModel.media!)
        case .some(let nsError as NSError) where (nsError.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool) == true:
            if isRecording {
                recordVideo()
            }
            coordinator.mediaCreated(viewModel.media!)
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

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        var requestOptions = [VNImageOption: Any]()
        
        if let cameraInstrictData = CMGetAttachment(
            sampleBuffer,
            key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix,
            attachmentModeOut: nil
        ) {
            requestOptions[.cameraIntrinsics] = cameraInstrictData
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: requestOptions)
        
        do {
            try imageRequestHandler.perform(requests)
        } catch {
            print(error)
        }
    }
}
