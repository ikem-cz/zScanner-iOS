//
//  PhotoPreviewViewController.swift
//  zScanner
//
//  Created by Jan Provazník on 07/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import SnapKit

class PhotoPreviewViewController: MediaPreviewViewController {

    // MARK: Instance part
    private var image: UIImage?
    
    // MARK: Lifecycle
    init(media: Media, viewModel: MediaListViewModel, coordinator: MediaPreviewCoordinator, editing: Bool) {
        
        super.init(viewModel: viewModel, media: media, coordinator: coordinator, editing: editing)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
            selector: #selector(self.keyboardNotification(notification:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func keyboardNotification(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let endFrameY = endFrame?.origin.y ?? 0
        let duration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let animationCurve: UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
        if endFrameY >= UIScreen.main.bounds.size.height {
            self.keyboardHeightConstraint?.update(inset: 8)
        } else {
            self.keyboardHeightConstraint?.update(inset: (endFrame?.size.height ?? 0) + 8)
        }
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: animationCurve,
            animations: { self.view.layoutIfNeeded() },
            completion: nil
        )
    }

    
    // MARK: View setup
    override func setupView() {
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.bottom.equalTo(buttonStackView.snp.top)
            make.top.leading.trailing.equalTo(safeArea)
        }
        
        view.addSubview(toolbar)
        toolbar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(imageView)
            make.height.equalTo(44)
        }
        
        view.addSubview(textbox)
        textbox.snp.makeConstraints { make in
            make.leading.trailing.equalTo(imageView)
            keyboardHeightConstraint = make.bottom.equalToSuperview().inset(8).constraint
        }
        
        textbox.addSubview(textInput)
        textInput.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.leading.equalToSuperview().inset(16)
            make.height.equalTo(30)
        }
        
        textbox.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(textInput.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(8)
            make.width.height.equalTo(30)
        }
        
        [textButton, bodyButton, cropButton, rotateButton]
            .forEach({ toolbar.addArrangedSubview($0) })
    }
    
    override func loadMedia() {
        do {
            let data = try Data(contentsOf: media.url)
            image = UIImage(data: data)
        } catch(let error) {
            print("Could not load data from url: ", error)
        }
    }
    
    // MARK: Helpers
    private var keyboardHeightConstraint: Constraint?
    
    @objc private func selectBodyPart() {
        coordinator.selectBodyPart(media: media)
    }
    
    @objc private func showTextInput() {
        toolbar.isHidden = true
        textbox.isHidden = false
        textInput.becomeFirstResponder()
    }
    
    @objc private func hideTextInput() {
        toolbar.isHidden = false
        textbox.isHidden = true
        textInput.resignFirstResponder()
        media.desription = textInput.text
    }
    
    @objc private func rotateImage() {
        guard let data = try? Data(contentsOf: media.url) else { return }
        var image = UIImage(data: data)
        image = image?.rotate(radians: .pi/2)
        try? image?.jpegData(compressionQuality: 0.8)?.write(to: media.url)
        self.image = image
        imageView.image = image
    }
    
    @objc private func cropImage() {
        media.cropRectangle = .default
    }
    
    // MARK: Lazy instance part
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var toolbar: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        return stackView
    }()
    
    private lazy var textbox: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        view.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        return view
    }()
    
    private lazy var textButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "textbox"), for: .normal)
        button.addTarget(self, action: #selector(showTextInput), for: .touchUpInside)
        return button
    }()
    
    private lazy var bodyButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "person"), for: .normal)
        button.addTarget(self, action: #selector(selectBodyPart), for: .touchUpInside)
        return button
    }()
    
    private lazy var cropButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "crop"), for: .normal)
        button.addTarget(self, action: #selector(cropImage), for: .touchUpInside)
        return button
    }()
    
    private lazy var rotateButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "rotate.right"), for: .normal)
        button.addTarget(self, action: #selector(rotateImage), for: .touchUpInside)
        return button
    }()
    
    private lazy var textInput: UITextField = {
        let text = UITextField()
        text.placeholder = "Popisek"
        text.delegate = self
        return text
    }()
    
    private lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "checkmark.circle"), for: .normal)
        button.addTarget(self, action: #selector(hideTextInput), for: .touchUpInside)
        return button
    }()
}
extension PhotoPreviewViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        hideTextInput()
        return true
    }
}
