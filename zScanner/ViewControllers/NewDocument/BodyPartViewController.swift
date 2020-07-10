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
    func showDefectSelector(for bodyPartId: String, list: ListPickerField<BodyDefectDomainModel>)
    func selected(_ defect: BodyDefectDomainModel)
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let defect = defectSelection.selected.value {
            coordinator.selected(defect)
        } else {
            segmentChanged(partSelector)
        }
    }
    
    // MARK: Helpers
    private let disposeBag = DisposeBag()
    private var selectedBodyPart: BodyPartDomainModel?
    
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
                guard let self = self else { return }
                
                switch result {
                case .awaitingInteraction:
                    break
                case .loading:
                    break
                case .success(let defects):
                    self.defectSelection = ListPickerField(title: self.selectorTitle, list: defects)
                    if let bodyPartId = self.selectedBodyPart?.id {
                        self.coordinator.showDefectSelector(for: bodyPartId, list: self.defectSelection)
                    }
                    
                case .error(let error):
                    self.handleError(error)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private var selectorTitle: String {
        "\("newDocument.defectList.title".localized) \(selectedBodyPart?.name ?? "")"
    }
    
    private func clearBodyView() {
        imageView.image = nil
        imageView.subviews.forEach { $0.removeFromSuperview() }
        selectedBodyPart = nil
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
        imageView.isUserInteractionEnabled = true
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
        selectedBodyPart = bodyPart
        viewModel.getDefects(for: bodyPart.id)
    }
}

protocol BodyPointDelegate: class {
    func bodyPartSelected(_ bodyPart: BodyPartDomainModel)
}

class BodyPoint: UIView {
    
    private unowned let delegate: BodyPointDelegate
    private let bodyPart: BodyPartDomainModel
    private var radius: CGFloat = 30
    
    
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
        let tap = UITapGestureRecognizer(target: self, action: #selector(BodyPoint.didTap))
        addGestureRecognizer(tap)
        
        addSubview(background)
        addSubview(imageView)

        background.snp.makeConstraints { make in
            make.edges.equalTo(imageView).inset(4)
        }
        
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(32)
        }

        addSubview(loading)
        loading.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private lazy var imageView: UIImageView = {
        let image = UIImageView(image: UIImage(systemName: "plus.square"))
        image.tintColor = .primary
        return image
    }()
    
    private lazy var background: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var loading: UIActivityIndicatorView = {
        let loading = UIActivityIndicatorView(style: .medium)
        loading.tintColor = .gray
        loading.hidesWhenStopped = true
        return loading
    }()
    
    @objc private func didTap() {
        loading.startAnimating()
        imageView.isHidden = true
        delegate.bodyPartSelected(bodyPart)
        isUserInteractionEnabled = false
    }
}
