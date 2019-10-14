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

    var prevValue: Double = 0
    
    func progressValue(is value: Double, animated: Bool = true) {
        
        if !animated {
            shapeLayer.strokeEnd = CGFloat(value)
            return
        }
        
        let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        basicAnimation.toValue = value
        basicAnimation.duration = 0.3
        basicAnimation.fillMode = .forwards
        basicAnimation.isRemovedOnCompletion = false
        shapeLayer.add(basicAnimation, forKey: "changeProgressValue\(value)")
        prevValue = value
    }
    
    //MARK: Helpers
    private let shapeLayer = CAShapeLayer()

    private func setup() {
        let circularPath = UIBezierPath(arcCenter: self.center, radius: 15, startAngle: -0.5 * .pi, endAngle: 1.5 * .pi, clockwise: true)
        shapeLayer.path = circularPath.cgPath
        shapeLayer.strokeColor = UIColor.black.cgColor
        shapeLayer.lineWidth = 2
        shapeLayer.strokeEnd = 0
        shapeLayer.lineCap = .round
        shapeLayer.fillColor = UIColor.clear.cgColor
        self.layer.addSublayer(shapeLayer)
    }
}
