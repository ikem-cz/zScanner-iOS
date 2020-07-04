//
//  BodyPartViewController.swift
//  zScanner
//
//  Created by Jakub Skořepa on 04/07/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift

protocol BodyPartCoordinator: BaseCoordinator {
    
}

class BodyPartViewController: BaseViewController {
    
    private unowned let coordinator: BodyPartCoordinator
    private let viewModel: BodyPartViewModel
    
    init(viewModel: BodyPartViewModel, coordinator: BodyPartCoordinator) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        
        super.init(coordinator: coordinator)
    }
    
    // MARK: Lifecycle
    override func loadView() {
        super.loadView()
        
        setupView()
        setupBindings()
    }
    
    // MARK: Helpers
    private let disposeBag = DisposeBag()
    
    private func setupBindings() {
        viewModel
            .bodyImage
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .awaitingInteraction:
                    break
                case .loading:
                    #warning("TODO")
                    break
                case .success(let image):
                    self?.imageView.image = image
                    self?.placePoints()
                case .error(let error):
                    #warning("TODO")
                    break
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func placePoints() {
        imageView.subviews.forEach { $0.removeFromSuperview() }
        
        let bodyView = viewModel.bodyViews[partSelector.selectedSegmentIndex]
        
        bodyView
            .bodyParts
            .map({
                BodyPoint(convert($0.location))
            })
            .forEach {
                imageView.addSubview($0)
            }
    }
    
    private func convert(_ point: CGPoint) -> CGPoint {
        let rect = imageView.contentClippingRect
        return CGPoint(x: point.x * rect.width + rect.minX, y: point.y * rect.height + rect.minY)
    }
    
    private func setupView() {
        view.addSubview(partSelector)
        partSelector.snp.makeConstraints { make in
            make.top.left.right.equalTo(safeArea).inset(8)
        }
        
        view.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.top.equalTo(partSelector.snp.bottom).offset(20)
            make.left.right.bottom.equalTo(safeArea).inset(8)
        }
    }
    
    @objc private func segmentChanged(_ segmentedControll: UISegmentedControl) {
        let bodyView = viewModel.bodyViews[segmentedControll.selectedSegmentIndex]
        viewModel.getImage(for: bodyView)
    }
    
    private lazy var partSelector: UISegmentedControl = {
        let selector = UISegmentedControl(items: viewModel.bodyViews.map({ $0.id }))
        selector.selectedSegmentIndex = 0
        selector.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        return selector
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
}

class BodyPoint: UIView {
    private var radius: CGFloat = 10
    
    init(_ location: CGPoint) {
        super.init(frame: CGRect(x: location.x - radius, y: location.y - radius, width: radius * 2, height: radius * 2))
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = 4
        
        let image = UIImageView(image: UIImage(systemName: "plus.square"))
        image.tintColor = .primary
        addSubview(image)
        image.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(-4)
        }
    }
}

