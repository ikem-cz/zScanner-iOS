//
//  PluggableViewController.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//  Source: http://basememara.com/pluggable-appdelegate-services/
//

import UIKit

class PluggableViewController: UIViewController {
    
    /// Lazy implementation of controller services list
    lazy var lazyServices: [ViewControllerService] = services
    
    /// List of controller services for binding to `UIViewController` events
    var services: [ViewControllerService] {
        return [ /* Populated from sub-class */ ]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lazyServices.forEach { $0.viewDidLoad(self) }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lazyServices.forEach { $0.viewWillAppear(self) }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lazyServices.forEach { $0.viewDidAppear(self) }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        lazyServices.forEach { $0.viewWillDisappear(self) }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        lazyServices.forEach { $0.viewDidDisappear(self) }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        lazyServices.forEach { $0.viewWillLayoutSubviews(self) }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        lazyServices.forEach { $0.viewDidLayoutSubviews(self) }
    }
}
