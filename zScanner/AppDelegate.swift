//
//  AppDelegate.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import Firebase
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow? {
        get { return appCoordinator?.window }
        set { assertionFailure("This will never happen without storyboards.") }
    }
    
    private var appCoordinator: AppCoordinator?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Realm.Configuration.defaultConfiguration.schemaVersion = 2
        runApp()
        return true
    }
    
    private func runApp() {
        appCoordinator = AppCoordinator()
        appCoordinator?.begin()
//        UIApplication.shared.windows.first?.layer.speed = 0.1
    }
}
