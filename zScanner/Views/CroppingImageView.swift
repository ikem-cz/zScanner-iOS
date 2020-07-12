//
//  CroppingImageView.swift
//  zScanner
//
//  Created by Jakub Skořepa on 10/07/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import Vision

enum CropMode: String {
    case edit
    case preview
    
    var title: String {
        return "newDocumentPhotos.scanMode[\(self.rawValue)].title".localized
    }
}

class CroppingImageView: UIImageView {
    
    let media: Media
    var mode: CropMode
    
    init?(media: Media) {
        switch media.type {
            case .photo: self.mode = .preview
            case .scan: self.mode = .edit
            case .video: return nil
        }
        
        self.media = media
        
        super.init(frame: .zero)
        self.image = imageFromUrl

        contentMode = .scaleAspectFit
        clipsToBounds = true
        isUserInteractionEnabled = true
        generateCorners()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        refreshCorners()
    }
    
    func setMode(_ mode: CropMode) {
        switch mode {
        case .edit:
            self.image = imageFromUrl

            rectangleLayer?.removeFromSuperlayer()
            rectangleLayer = newRectangleLayer()
            self.layer.addSublayer(rectangleLayer!)
            generateCorners()
            corners.forEach({ self.addSubview($0) })
        case .preview:
            rectangleLayer?.removeFromSuperlayer()
            rectangleLayer = nil
            corners.forEach({ $0.removeFromSuperview() })
            self.image = media.thumbnail
        }
    }
    
    // MARK: Helpers
    private var rectangleLayer: CAShapeLayer?
    private var corners: [RectangleCorner] = []
    
    private var imageFromUrl: UIImage? {
        (try? Data(contentsOf: media.url)).flatMap({ UIImage(data: $0) })
    }
    
    private func generateCorners() {
        guard let rectangle = media.cropRectangle else { return }
        
        corners.forEach({ $0.removeFromSuperview() })
        corners = [
            RectangleCorner(
                point: convertFromCamera(rectangle.topLeft),
                didMovedTo: { [weak self] newValue in self?.updateRectangle(corner: .topLeft, newCorner: newValue)
            }),
            RectangleCorner(
                point: convertFromCamera(rectangle.topRight),
                didMovedTo: { [weak self] newValue in self?.updateRectangle(corner: .topRight, newCorner: newValue)
            }),
            RectangleCorner(
                point: convertFromCamera(rectangle.bottomLeft),
                didMovedTo: { [weak self] newValue in self?.updateRectangle(corner: .bottomLeft, newCorner: newValue)
            }),
            RectangleCorner(
                point: convertFromCamera(rectangle.bottomRight),
                didMovedTo: { [weak self] newValue in self?.updateRectangle(corner: .bottomRight, newCorner: newValue)
            })
        ]
    }
    
    private func newRectangleLayer() -> CAShapeLayer {
        let points = media.cropRectangle?.points.map { convertFromCamera($0) } ?? []
        
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
    
    private func updateRectangle(corner: UIRectCorner, newCorner: CGPoint) {
        media.cropRectangle = media.cropRectangle?.updatingCorner(corner, newCorner: convertToCamera(newCorner), square: media.type == .photo)
        rectangleLayer?.removeFromSuperlayer()
        rectangleLayer = newRectangleLayer()
        layer.addSublayer(rectangleLayer!)
        refreshCorners()
    }
        
    private func refreshCorners() {
        guard let rectangle = media.cropRectangle else { return }
        
        corners[0].position(to: convertFromCamera(rectangle.topLeft))
        corners[1].position(to: convertFromCamera(rectangle.topRight))
        corners[2].position(to: convertFromCamera(rectangle.bottomLeft))
        corners[3].position(to: convertFromCamera(rectangle.bottomRight))
    }
    
    private func convertFromCamera(_ point: CGPoint) -> CGPoint {
        let rect = contentClippingRect
        return CGPoint(x: point.x * rect.width + rect.minX, y: (1 - point.y) * rect.height + rect.minY)
    }
    
    private func convertToCamera(_ point: CGPoint) -> CGPoint {
        let rect = contentClippingRect
        return CGPoint(x: (point.x - rect.minX) / rect.width, y: 1 - (point.y - rect.minY) / rect.height)
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
        self.isUserInteractionEnabled = true
        
        addGestureRecognizer(panGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func move(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: nil)
        
        
        let x = min(max(frame.origin.x + translation.x, -radius), superview!.bounds.width - radius)
        let y = min(max(frame.origin.y + translation.y, -radius), superview!.bounds.height - radius)
        
        let newFrame = CGRect(
            x: x,
            y: y,
            width: frame.width,
            height: frame.height
        )
        let newCenter = CGPoint(x: newFrame.origin.x + radius, y: newFrame.origin.y + radius)

        frame.origin = newFrame.origin
        callback(newCenter)

        recognizer.setTranslation(.zero, in: nil)
    }
    
    func position(to newCenter: CGPoint) {
        frame = CGRect(x: newCenter.x - radius, y: newCenter.y - radius, width: radius * 2, height: radius * 2)
    }
}

extension VNRectangleObservation {
    var points: [CGPoint] {
        [topLeft, topRight, bottomRight, bottomLeft]
    }
    
    func updatingCorner(_ corner: UIRectCorner, newCorner: CGPoint, square: Bool) -> VNRectangleObservation {
        if square {
            if corner.contains(.topLeft) {
                return VNRectangleObservation(
                    requestRevision: self.requestRevision,
                    topLeft: newCorner,
                    bottomLeft: CGPoint(x: newCorner.x, y: bottomLeft.y),
                    bottomRight: bottomRight,
                    topRight: CGPoint(x: topRight.x, y: newCorner.y)
                )
            } else if corner.contains(.bottomLeft) {
                return VNRectangleObservation(
                    requestRevision: self.requestRevision,
                    topLeft: CGPoint(x: newCorner.x, y: topLeft.y),
                    bottomLeft: newCorner,
                    bottomRight: CGPoint(x: bottomRight.x, y: newCorner.y),
                    topRight: topRight
                )
            } else if corner.contains(.bottomRight) {
                return VNRectangleObservation(
                    requestRevision: self.requestRevision,
                    topLeft: topLeft,
                    bottomLeft: CGPoint(x: bottomLeft.x, y: newCorner.y),
                    bottomRight: newCorner,
                    topRight: CGPoint(x: newCorner.x, y: topRight.y)
                )
            } else if corner.contains(.topRight) {
                return VNRectangleObservation(
                    requestRevision: self.requestRevision,
                    topLeft: CGPoint(x: topLeft.x, y: newCorner.y),
                    bottomLeft: bottomLeft,
                    bottomRight: CGPoint(x: newCorner.x, y: bottomRight.y),
                    topRight: newCorner
                )
            } else {
                return self
            }
        } else {
            return VNRectangleObservation(
                requestRevision: self.requestRevision,
                topLeft: corner.contains(.topLeft) ? newCorner : topLeft,
                bottomLeft: corner.contains(.bottomLeft) ? newCorner : bottomLeft,
                bottomRight: corner.contains(.bottomRight) ? newCorner : bottomRight,
                topRight: corner.contains(.topRight) ? newCorner : topRight
            )
        }
        
    }
}
