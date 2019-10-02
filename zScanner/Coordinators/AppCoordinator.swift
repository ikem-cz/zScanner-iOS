//
//  AppCoordinator.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

class AppCoordinator: Coordinator {
    
    //MARK: - Instance part
    init() {
        let window = UIWindow(frame: UIScreen.main.bounds)
        super.init(window: window, navigationController: nil)
    }
    
    // MARK: Inteface
    func begin() {
        showSplashScreen()
    }
    
    // MARK: Navigation methods
    private func showSplashScreen() {
        let viewController = SeaCatSplashViewController(coordinator: self)
        changeWindowControllerTo(viewController)
    }
    
    private func runLoginFlow() {
        let coordinator = LoginCoordinator(flowDelegate: self, window: window)
        addChildCoordinator(coordinator)
        coordinator.begin()
    }
    
    private func startDocumentsCoordinator(with userSession: UserSession) {
        let coordinator = DocumentsCoordinator(userSession: userSession, flowDelegate: self, window: window)
        addChildCoordinator(coordinator)
        coordinator.begin()
    }
    
    // MARK: Helpers
    private let database: Database = try! RealmDatabase()
    private let tracker: Tracker = FirebaseAnalytics()
    
    private func storeUserSession(_ userSession: UserSession) {
        let databaseLogin = LoginDatabaseModel(login: userSession.login)
        database.saveObject(databaseLogin)
    }
    
    private var restoredUserSession: UserSession? {
        if let login = database.loadObjects(LoginDatabaseModel.self).first?.toDomainModel() {
            return UserSession(login: login)
        }
        return nil
    }
    
    private func removeUserSession() {
        database.deleteAll(of: LoginDatabaseModel.self)
    }
}

// MARK: - SeaCatSplashCoordinator implementation
extension AppCoordinator: SeaCatSplashCoordinator {
    func seaCatInitialized() {
        
        // It's not about SeaCat is ready but more about certificate exists.
        // In this case we are creating certificate with credentials on login.
        // Therefore is more like credentials exists -> is logged in
        if let userSession = restoredUserSession, SeaCatClient.isReady() {
            startDocumentsCoordinator(with: userSession)
        } else {
            self.runLoginFlow()
        }
    }
}

// MARK: - LoginFlowDelegate implementation
extension AppCoordinator: LoginFlowDelegate {
    func successfulLogin(userSession: UserSession) {
        tracker.track(.login)
        storeUserSession(userSession)
        startDocumentsCoordinator(with: userSession)
    }
}

// MARK: - DocumentsFlowDelegate implementation
extension AppCoordinator: DocumentsFlowDelegate {
    func logout() {
        removeUserSession()
        SeaCatClient.reset()
        tracker.track(.logout)
        runLoginFlow()
    }
}
