//
//  LoadingCircle.swift
//  zScanner
//
//  Created by Martin Georgiu on 16/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

class LoadingCircle: UIView {
    
    //MARK: Instance part
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func progressValue(is value: Double) {
        let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        basicAnimation.toValue = value
        basicAnimation.duration = 2
        basicAnimation.fillMode = .forwards
        basicAnimation.isRemovedOnCompletion = false
        shapeLayer.add(basicAnimation, forKey: "changeProgressValue")        
    }
    
    //MARK: Helpers
    private let shapeLayer = CAShapeLayer()

    private func setup() {
        let circularPath = UIBezierPath(arcCenter: self.center, radius: 15, startAngle: -CGFloat.pi / 2, endAngle: 2 * CGFloat.pi, clockwise: true)
        shapeLayer.path = circularPath.cgPath
        shapeLayer.strokeColor = UIColor.black.cgColor
        shapeLayer.lineWidth = 2
        shapeLayer.strokeEnd = 0
        shapeLayer.lineCap = .round
        shapeLayer.fillColor = UIColor.clear.cgColor
        self.layer.addSublayer(shapeLayer)
    }
}
