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
    func showSelector<T: ListItem>(for list: ListPickerField<T>)
}

class BodyPartViewController: BaseViewController, ErrorHandling {
    
    private unowned let coordinator: BodyPartCoordinator
    private let viewModel: BodyPartViewModel
    private var defectSelection = ListPickerField<BodyDefectDomainModel>(title: "", list: [])
    
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
                    self?.loadingView.stopAnimating()
                    
                case .loading:
                    self?.clearBodyView()
                    self?.loadingView.startAnimating()
                    
                case .success(let image):
                    self?.loadingView.stopAnimating()
                    self?.imageView.image = image
                    self?.placePoints()
                    
                case .error(let error):
                    self?.clearBodyView()
                    self?.loadingView.stopAnimating()
                    self?.handleError(error)
                }
            })
            .disposed(by: disposeBag)
        
        
        viewModel
            .defects
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .awaitingInteraction:
                    break
                case .loading:
                    break
                case .success(let defects):
                    self?.defectSelection = ListPickerField(title: "Neco title", list: defects)
                    self?.coordinator.showSelector(for: self!.defectSelection)
                    
                case .error(let error):
                    self?.handleError(error)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func clearBodyView() {
        imageView.image = nil
        imageView.subviews.forEach { $0.removeFromSuperview() }
    }
    
    private func placePoints() {
        viewModel
            .bodyViews[partSelector.selectedSegmentIndex]
            .bodyParts
            .map({
                BodyPoint($0, at: convert($0.location), delegate: self)
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
        
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.center.equalTo(imageView)
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
    
    private lazy var loadingView: UIActivityIndicatorView = {
        let loadingview = UIActivityIndicatorView(style: .large)
        loadingview.tintColor = .gray
        loadingview.hidesWhenStopped = true
        return loadingview
    }()
}

extension BodyPartViewController: BodyPointDelegate {
    func bodyPartSelected(_ bodyPart: BodyPartDomainModel) {
        viewModel.getDefects(for: bodyPart.id)
    }
}

protocol BodyPointDelegate: class {
    func bodyPartSelected(_ bodyPart: BodyPartDomainModel)
}

class BodyPoint: UIView {
    
    private unowned let delegate: BodyPointDelegate
    private let bodyPart: BodyPartDomainModel
    private var radius: CGFloat = 10
    
    
    init(_ bodyPart: BodyPartDomainModel, at location: CGPoint, delegate: BodyPointDelegate) {
        self.bodyPart = bodyPart
        self.delegate = delegate
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
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(BodyPoint.didTap))
        tap.delegate = self
        image.addGestureRecognizer(tap)
        image.isUserInteractionEnabled = true
    }
    
    @objc private func didTap() {
        delegate.bodyPartSelected(bodyPart)
    }
}

extension BodyPoint: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

