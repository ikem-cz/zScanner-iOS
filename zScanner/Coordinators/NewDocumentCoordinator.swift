//
//  NewDocumentCoordinator.swift
//  zScanner
//
//  Created by Jakub Skořepa on 28/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol NewDocumentFlowDelegate: FlowDelegate {
    func newDocumentCreated(_ documentViewModel: DocumentViewModel)
}

class NewDocumentCoordinator: Coordinator {
    enum Step: Equatable {
        case folder
        case documentType
        case media
        case mediaList
    }
    
    // MARK: Instance part
    unowned private let flowDelegate: NewDocumentFlowDelegate
    private var newDocument = DocumentDomainModel.emptyDocument
    private let mode: DocumentMode
    private let steps: [Step]
    private var currentStep: Step
    private var mediaViewModel: MediaViewModel?
    private let defaultMediaType = MediaType.photo
    private let mediaSourceTypes = [
         MediaType.photo,
         MediaType.video
     ]
    
    init?(for mode: DocumentMode, flowDelegate: NewDocumentFlowDelegate, window: UIWindow, navigationController: UINavigationController? = nil) {
        guard mode != .undefined else { return nil }

        self.flowDelegate = flowDelegate
        
        self.mode = mode
        self.steps = NewDocumentCoordinator.steps(for: mode)
        
        // If mode is .photo or .video the step for setting documentType is skipped, but the documentMode is needed later.
        // The documentMode is set now to prevent unexpected behavior.
        switch mode {
        case .photo, .video:
            newDocument.type.mode = mode
        default:
            break
        }
        
        guard let firstStep = steps.first else { return nil }
        self.currentStep = firstStep
        
        super.init(window: window, navigationController: navigationController)
    }
    
    // MARK: Interface
    func begin() {
        showCurrentStep()
    }
    
    // MARK: Helepers
    private let database: Database = try! RealmDatabase()
    private let networkManager: NetworkManager = IkemNetworkManager(api: NativeAPI())
    private let tracker: Tracker = FirebaseAnalytics()
    
    private func showCurrentStep() {
        switch currentStep {
        case .folder:
            showFolderSelectionScreen()
        case .documentType:
            showDocumentTypeSelectionScreen()
        case .media:
            showNewMediaScreen(mediaType: defaultMediaType, mediaSourceTypes: mediaSourceTypes)
        case .mediaList:
            showMediaListScreen()
        }
    }
    
    private func showFolderSelectionScreen() {
        let viewModel = NewDocumentFolderViewModel(database: database, networkManager: networkManager, tracker: tracker)
        let viewController = NewDocumentFolderViewController(viewModel: viewModel, coordinator: self)
        push(viewController)
    }
    
    private func showDocumentTypeSelectionScreen() {
        let viewModel = NewDocumentTypeViewModel(documentMode: mode, database: database)
        let viewController = NewDocumentTypeViewController(viewModel: viewModel, coordinator: self)
        push(viewController)
    }
    
    private func showNewMediaScreen(mediaType: MediaType, mediaSourceTypes: [MediaType]) {
        if !(viewControllers.first is CameraViewController) {
            popAll(animated: false)
        }
        
        let viewModel = CameraViewModel(initialMode: mediaType, folderName: newDocument.folder.name, mediaSourceTypes: mediaSourceTypes)
        let viewController = CameraViewController(viewModel: viewModel, coordinator: self)
        
        if let index = navigationController?.viewControllers.firstIndex(where: { $0 is CameraViewController }) {
            navigationController?.viewControllers.insert(viewController, at: index)
            pop(to: viewController, animated: true)
        } else {
            push(viewController, animated: true)
        }
    }
    
    private func showPhotoPreviewScreen(fileURL: URL) {
        guard let mediaViewModel = mediaViewModel else { return }
        let viewController = PhotoPreviewViewController(imageURL: fileURL, viewModel: mediaViewModel, coordinator: self)
        push(viewController)
    }
    
    private func showVideoPreviewScreen(fileURL: URL) {
        guard let mediaViewModel = mediaViewModel else { return }
        let viewController = VideoPreviewViewController(videoURL: fileURL, viewModel: mediaViewModel, coordinator: self)
        push(viewController)
    }
    
    private func showMediaListScreen() {
        guard let mediaViewModel = mediaViewModel else { return }
        let viewController = MediaListViewController(viewModel: mediaViewModel, coordinator: self)
        push(viewController)
    }
    
    private func showListItemSelectionScreen<T: ListItem>(for list: ListPickerField<T>) {
        let viewController = ListItemSelectionViewController(viewModel: list, coordinator: self)
        push(viewController)
    }
    
    private func finish() {

        let databaseDocument = DocumentDatabaseModel(document: newDocument)
        database.saveObject(databaseDocument)
        
        let documentViewModel = DocumentViewModel(document: newDocument, networkManager: networkManager, database: database)
        documentViewModel.uploadDocument()
        
        popAll()
        flowDelegate.newDocumentCreated(documentViewModel)
        flowDelegate.coordinatorDidFinish(self)
    }
    
    private func resolveNextStep() {
        guard let index = steps.firstIndex(of: currentStep) else {
            fatalError("Current step is not present in list of steps")
        }
        
        let nextIndex = index + 1
        
        if nextIndex >= steps.count {
            finish()
            return
        }
        
        currentStep = steps[nextIndex]
        showCurrentStep()
    }
    
    private func resolvePreviousStep() {
        guard let index = steps.firstIndex(of: currentStep) else {
            fatalError("Current step is not present in list of steps")
        }
        
        let prevIndex = index - 1
        
        if prevIndex < 0 {
            pop()
            flowDelegate.coordinatorDidFinish(self)
            return
        }
        
        currentStep = steps[prevIndex]
        pop()
    }
    
    private func savePagesToDocument(_ pages: [UIImage]) {

        // Store images
        pages
            .enumerated()
            .forEach({ (index, image) in
                let page = PageDomainModel(image: image, index: index, correlationId: newDocument.id)
                newDocument.pages.append(page)
            })
        }
    
    private static func steps(for mode: DocumentMode) -> [Step] {
        switch mode {
        case .document, .examination, .ext:
            return [.folder, .documentType, .media, .mediaList]
        case .photo:
            return [.folder, .media, .mediaList]
        case .video:
            return [.folder, .media, .mediaList]
        case .undefined:
            return []
        }
    }
    
    // MARK: - BaseCordinator implementation
    override func willPreventPop(for sender: BaseViewController) -> Bool {
        switch sender {
        case
        is MediaListViewController,
        is NewDocumentTypeViewController,
        is NewDocumentFolderViewController:
            return true
        default:
            return false
        }
    }
    
    override func backButtonPressed(sender: BaseViewController) {
        if willPreventPop(for: sender) {
            showPopConfirmationDialog(presentOn: sender, popHandler: { [unowned self] in
                self.resolvePreviousStep()
            })
        } else {
            super.backButtonPressed(sender: sender)
        }
    }
    
    private func showPopConfirmationDialog(presentOn viewController: BaseViewController, popHandler: @escaping EmptyClosure) {
        let alert = UIAlertController(title: "newDocument.popAlert.title".localized, message: "newDocument.popAlert.message".localized, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "newDocument.popAlert.confirm".localized, style: .default, handler: { _ in popHandler() }))
        alert.addAction(UIAlertAction(title: "newDocument.popAlert.cancel".localized, style: .cancel, handler: nil))
        
        viewController.present(alert, animated: true)
    }
}

// MARK: - NewDocumentTypeCoordinator implementation
extension NewDocumentCoordinator: NewDocumentFolderCoordinator {
    func showNextStep() {
        resolveNextStep()
    }
    
    func saveFolder(_ folder: FolderDomainModel, searchMode: SearchMode) {
        newDocument.folder = folder
        let databaseFolder = FolderDatabaseModel(folder: folder)
        FolderDatabaseModel.updateLastUsage(of: databaseFolder)
        tracker.track(.userFoundBy(searchMode))
    }
}

// MARK: - NewDocumentTypeCoordinator implementation
extension NewDocumentCoordinator: NewDocumentTypeCoordinator {
    func showSelector<T: ListItem>(for list: ListPickerField<T>) {
        showListItemSelectionScreen(for: list)
    }
    
    func saveFields(_ fields: [FormField]) {
        for field in fields {
            switch field {
            case let textField as TextInputField:
                newDocument.notes = textField.text.value
            case let datePicker as DateTimePickerField:
                if let date = datePicker.date.value {
                    newDocument.date = date
                }
            case let listPicker as ListPickerField<DocumentTypeDomainModel>:
                if let type = listPicker.selected.value {
                    newDocument.type = type
                }
            default:
                break
            }
        }
    }
}

// MARK: - ListItemSelectionCoordinator implementation
extension NewDocumentCoordinator: ListItemSelectionCoordinator {}

// MARK: - CameraCoordinator implementation
extension NewDocumentCoordinator: CameraCoordinator {
    func mediaCreated(_ type: MediaType, url: URL) {
        if mediaViewModel == nil {
            mediaViewModel = MediaViewModel(folderName: newDocument.folder.name, mediaType: type, tracker: tracker)
        }
        
        if type == .photo {
            showPhotoPreviewScreen(fileURL: url)
        } else if type == .video {
            showVideoPreviewScreen(fileURL: url)
        }
    }
}

// MARK: - MediaPreviewCoordinator implementation
extension NewDocumentCoordinator: MediaPreviewCoordinator {
    func createNewMedia(mediaType: MediaType) {
        guard let mediaViewModel = mediaViewModel else { return }
        showNewMediaScreen(mediaType: mediaViewModel.mediaType, mediaSourceTypes: [mediaViewModel.mediaType])
    }
}

// MARK: - NewDocumentMediaCoordinator implementation
extension NewDocumentCoordinator: MediaListCoordinator {
    func saveMediaList() {
        #warning("Sending photo for this time")
        if mediaViewModel?.mediaType == .photo {
            var photos: [UIImage] = []
            mediaViewModel?.mediaArray.value.forEach( { (_, image) in
                photos.append(image)
            })
            savePagesToDocument(photos)
        }
    }
}
