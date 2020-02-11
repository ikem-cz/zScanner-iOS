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
        case photos
    }
    
    // MARK: Instance part
    unowned private let flowDelegate: NewDocumentFlowDelegate
    private var newDocument = DocumentDomainModel.emptyDocument
    private let mode: DocumentMode
    private let steps: [Step]
    private var currentStep: Step
    
    init?(for mode: DocumentMode, flowDelegate: NewDocumentFlowDelegate, window: UIWindow, navigationController: UINavigationController? = nil) {
        guard mode != .undefined else { return nil }

        self.flowDelegate = flowDelegate
        
        self.mode = mode
        self.steps = NewDocumentCoordinator.steps(for: mode)
        
        // If mode is .photo the step for setting documentType is skipped, but the documentMode is needed later.
        // The documentMode is set now to prevent unexpected behavior.
        if mode == .photo {
            newDocument.type.mode = .photo
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
        case .photos:
            showPhotosSelectionScreen()
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
    
    private func showPhotosSelectionScreen() {
        let viewModel = NewDocumentPhotosViewModel(tracker: tracker)
        let viewController = NewDocumentPhotosViewController(viewModel: viewModel, coordinator: self)
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
            return [.folder, .photos, .documentType]
    }
    
    // MARK: - BaseCordinator implementation
    override func willPreventPop(for sender: BaseViewController) -> Bool {
        switch sender {
        case
        is NewDocumentPhotosViewController,
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

// MARK: - ListItemSelectionCoordinator implementation
extension NewDocumentCoordinator: NewDocumentPhotosCoordinator {
    func savePhotos(_ photos: [UIImage]) {
        savePagesToDocument(photos)
    }
}
