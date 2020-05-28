//
//  BottomSheetPresenting.swift
//  zScanner
//
//  Created by Jakub Skořepa on 23/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol Presentable {
    func willDismiss()
    func willExpand()
}

class BottomSheetPresenting: BaseViewController {
    
    private var expanded = false
    
    var sheetViewController: UIViewController? {
        didSet {
            oldValue?.removeFromParent()
            oldValue?.view.removeFromSuperview()
            sheetViewController.flatMap({ addChild($0) })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addBottomSheetView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupBottomSheet()
    }
    
    func addBottomSheetView() {
        view.addSubview(presentedView)
        sheetViewController?.didMove(toParent: self)
        presentedView.addGestureRecognizer(panGesture)
    }
    
    func setupBottomSheet() {
        presentedView.frame = expanded ? frameOfExpandedView : frameOfDismissedView
    }
    
    func dismissBottomSheet() {
        (sheetViewController as? Presentable)?.willDismiss()
        
        UIView.animate(withDuration: 0.25) {
            self.presentedView.frame = self.frameOfDismissedView
            self.expanded = false
        }
        
        view.endEditing(true)
    }
    
    func expandBottomSheet() {
        (sheetViewController as? Presentable)?.willExpand()
        
        UIView.animate(withDuration: 0.25) {
            self.presentedView.frame = self.frameOfExpandedView
            self.expanded = true
        }
    }
    
    @objc private func drag(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .changed:
            view.bringSubviewToFront(presentedView)
            let translation = gesture.translation(in: view)
            let targetCenterY = presentedView.center.y + translation.y

            presentedView.center.y = targetCenterY
            gesture.setTranslation(.zero, in: view)

        case .ended:
            let containerHeight = view.frame.height
            let position = presentedView.convert(view.frame, to: nil).origin.y
            let relativePosition = position - (containerHeight - frameOfExpandedView.height)

            let treshold: CGFloat = 100
            if expanded {
                relativePosition < treshold ? expandBottomSheet() : dismissBottomSheet()
            } else {
                position < frameOfDismissedView.origin.y - treshold ? expandBottomSheet() : dismissBottomSheet()
            }

            gesture.setTranslation(.zero, in: view)

        default:
            break
        }
    }
    
    private let heightOfCollapsedSheet: CGFloat = 128
    private let gapAboveExpandedSheet: CGFloat = 78
    
    private var frameOfExpandedView: CGRect {
        return CGRect(
            x: 0,
            y: gapAboveExpandedSheet,
            width: view.frame.width,
            height: view.frame.height - gapAboveExpandedSheet
        )
    }
    
    private var frameOfDismissedView: CGRect {
        let safeAreaCompensation = (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0) / 2
        return CGRect(
            x: 0,
            y: view.frame.height - heightOfCollapsedSheet - safeAreaCompensation,
            width: view.frame.width,
            height: view.frame.height - gapAboveExpandedSheet
        )
    }

    private lazy var panGesture: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(drag(_:)))
        return pan
    }()
    
    private lazy var presentedView: UIView = {
        let view = UIView()
        guard let presentedView = sheetViewController?.view else { return view }
        
        let shadow = GradientView()
        
        view.addSubview(shadow)
        view.addSubview(presentedView)
        view.addSubview(handlerView)
        
        shadow.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(20)
        }
        
        handlerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(presentedView)
            make.height.equalTo(21)
        }
        
        presentedView.snp.makeConstraints { make in
            make.top.equalTo(shadow).offset(10)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        return view
    }()
    
    private lazy var handlerView: UIView = {
        let view = UIView()
        view.backgroundColor = nil
        let handle = UIView(frame: CGRect(x: 0, y: 0, width: 48, height: 5))
        view.addSubview(handle)
        handle.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(48)
            make.height.equalTo(5)
        }
        handle.roundCorners(radius: 2.5)
        handle.backgroundColor = UIColor(hex: 0xd1d0d6)
        return view
    }()
}
