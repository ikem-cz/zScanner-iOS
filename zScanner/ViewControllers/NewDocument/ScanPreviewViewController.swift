//
//  ScanPreviewViewController.swift
//  zScanner
//
//  Created by Jan Provazník on 07/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import Vision

enum ScanMode: String {
    case edit
    case preview
    
    var title: String {
        return "newDocumentPhotos.scanMode[\(self.rawValue)].title".localized
    }
}

class ScanPreviewViewController: MediaPreviewViewController {

    // MARK: Instance part
    private var image: UIImage?
    private var scan: ScanMedia { media as! ScanMedia }
    
    // MARK: Lifecycle
    init(media: ScanMedia, viewModel: NewDocumentMediaViewModel, coordinator: MediaPreviewCoordinator) {
        
        super.init(viewModel: viewModel, media: media, coordinator: coordinator)
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupSelection()
    }
    
    // MARK: View setup
    override func setupView() {
        view.addSubview(modeSwich)
        modeSwich.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(safeArea).inset(8)
        }
        
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.top.equalTo(modeSwich.snp.bottom).offset(8)
            make.leading.trailing.equalTo(safeArea)
            make.bottom.equalTo(buttonStackView.snp.top)
        }
    }
    
    var corners: [UIView] = []
    
    func setupSelection() {
        rectangleLayer = newRectangleLayer()
        imageView.layer.addSublayer(rectangleLayer!)
        corners = [
            RectangleCorner(
                point: convertFromCamera(scan.rectangle.topLeft),
                didMovedTo: { [weak self] newValue in self?.updateRectangle(corner: .topLeft, newCorner: newValue)
            }),
            RectangleCorner(
                point: convertFromCamera(scan.rectangle.topRight),
                didMovedTo: { [weak self] newValue in self?.updateRectangle(corner: .topRight, newCorner: newValue)
            }),
            RectangleCorner(
                point: convertFromCamera(scan.rectangle.bottomLeft),
                didMovedTo: { [weak self] newValue in self?.updateRectangle(corner: .bottomLeft, newCorner: newValue)
            }),
            RectangleCorner(
                point: convertFromCamera(scan.rectangle.bottomRight),
                didMovedTo: { [weak self] newValue in self?.updateRectangle(corner: .bottomRight, newCorner: newValue)
            })
        ]
        corners.forEach({ imageView.addSubview($0) })
        imageView.isUserInteractionEnabled = true
    }
    
    func updateRectangle(corner: UIRectCorner, newCorner: CGPoint) {
        scan.rectangle = scan.rectangle.updatingCorner(corner, newCorner: convertToCamera(newCorner))
        rectangleLayer?.removeFromSuperlayer()
        rectangleLayer = newRectangleLayer()
        imageView.layer.addSublayer(rectangleLayer!)
    }

    // MARK: Helpers
    let modes = [ScanMode.edit, .preview]
    
    override func loadMedia() {
        do {
            let data = try Data(contentsOf: media.url)
            image = UIImage(data: data)
        } catch(let error) {
            print("Could not load data from url: ", error)
        }
    }
    
    @objc private func switchMode(_ segmentedControl: UISegmentedControl) {
        let mode = modes[segmentedControl.selectedSegmentIndex]
        switch mode {
        case .edit:
            rectangleLayer?.removeFromSuperlayer()
            rectangleLayer = newRectangleLayer()
            imageView.layer.addSublayer(rectangleLayer!)
            corners.forEach({ imageView.addSubview($0) })
            imageView.image = image
        case .preview:
            rectangleLayer?.removeFromSuperlayer()
            rectangleLayer = nil
            corners.forEach({ $0.removeFromSuperview() })
            imageView.image = scan.thumbnail
        }
    }
        
    
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
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    private var rectangleLayer: CAShapeLayer?
    
    func newRectangleLayer() -> CAShapeLayer {
        let points = scan.rectangle.points.map { convertFromCamera($0) }
        
        let layer = CAShapeLayer()
        layer.fillColor = #colorLiteral(red: 0.4506933627, green: 0.5190293554, blue: 0.9686274529, alpha: 0.2050513699)
        layer.strokeColor = #colorLiteral(red: 0.3328347607, green: 0.236689759, blue: 1, alpha: 1)
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
        let orientation = UIApplication.shared.statusBarOrientation
        let rect = imageView.contentClippingRect
        
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
    
    func convertToCamera(_ point: CGPoint) -> CGPoint {
        let orientation = UIApplication.shared.statusBarOrientation
        let rect = imageView.contentClippingRect
        
        let point = CGPoint(x: (point.x - rect.minX) / rect.width, y: (point.y - rect.minY) / rect.height)
        
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
        return CGPoint(x: x, y: y)
    }
}

class RectangleCorner: UIView {
    let padding: CGFloat = 20
    let radius: CGFloat = 20
    let callback: (CGPoint) -> Void
    lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(move(_:)))
    
    init(point: CGPoint, didMovedTo: @escaping (CGPoint) -> Void) {
        self.callback = didMovedTo
        
        super.init(frame: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
        
        let layer = CAShapeLayer()
        layer.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 2.0 * radius, height: 2.0 * radius), cornerRadius: radius).cgPath
        layer.fillColor = #colorLiteral(red: 0.4506933627, green: 0.5190293554, blue: 0.9686274529, alpha: 0.2050513699)
        layer.strokeColor = #colorLiteral(red: 0.3328347607, green: 0.236689759, blue: 1, alpha: 1)
        self.layer.addSublayer(layer)
        isUserInteractionEnabled = true
        
        addGestureRecognizer(panGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func move(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: nil)
        let newFrame = CGRect(
            x: frame.origin.x + translation.x,
            y: frame.origin.y + translation.y,
            width: frame.width,
            height: frame.height
        )
        let newCenter = CGPoint(x: newFrame.origin.x + radius, y: newFrame.origin.y + radius)

        frame.origin = newFrame.origin
        callback(newCenter)

        recognizer.setTranslation(.zero, in: nil)
    }
}

extension VNRectangleObservation {
    var points: [CGPoint] {
        [topLeft, topRight, bottomRight, bottomLeft]
    }
    
    func updatingCorner(_ corner: UIRectCorner, newCorner: CGPoint) -> VNRectangleObservation {
        VNRectangleObservation(
            requestRevision: self.requestRevision,
            topLeft: corner.contains(.topLeft) ? newCorner : topLeft,
            bottomLeft: corner.contains(.bottomLeft) ? newCorner : bottomLeft,
            bottomRight: corner.contains(.bottomRight) ? newCorner : bottomRight,
            topRight: corner.contains(.topRight) ? newCorner : topRight
        )
    }
}
