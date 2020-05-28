//
//  UIView.swift
//  zScanner
//
//  Created by Jakub Skořepa on 17/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

extension UIView {

    func roundCorners(corners: UIRectCorner = [.allCorners], radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }

    func dropShadow() {
        layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        layer.shadowOffset = CGSize.zero
        layer.shadowRadius = 5
        layer.shadowOpacity = 1
        layer.masksToBounds = false
    }
}
