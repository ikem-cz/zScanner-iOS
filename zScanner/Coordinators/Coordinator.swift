//
//  Coordinator.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol FlowDelegate: class {
    func coordinatorDidFinish(_ coordinator: Coordinator)
}

// MARK: -
class Coordinator {
    private var childCoordinators: [Coordinator] = []
    private(set) var viewControllers: [UIViewController] = []
    
    let window: UIWindow
    var navigationController: UINavigationController?
    
    init(window: UIWindow, navigationController: UINavigationController? = nil) {
        self.window = window
        self.navigationController = navigationController
    }
    
    // MARK: Child coordinators
    func addChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }
    
    func removeChildCoordinator(_ coordinator: Coordinator) {
        let removed = childCoordinators.remove(coordinator) != nil
        if !removed {
            assertionFailure("Coordinator \(type(of: coordinator)) was not on stack!")
        }
    }
    
    // MARK: View controllers
    func push(_ viewController: UIViewController, animated: Bool = true) {
        viewControllers.append(viewController)
        if let navigationController = navigationController {
            navigationController.pushViewController(viewController, animated: animated)
        } else {
            let navigationController = UINavigationController(rootViewController: viewController)
            changeWindowControllerTo(navigationController)
            self.navigationController = navigationController
        }
    }
    
    func pop(animated: Bool = true) {
        let _ = navigationController?.popViewController(animated: animated)
        let _ = viewControllers.popLast()
    }
    
    func pop(to viewController: BaseViewController, animated: Bool = true) {
        guard
            let navigationStack = navigationController?.viewControllers,
            let index = navigationStack.firstIndex(of: viewController),
            index < navigationStack.count - 1
            else {
                assertionFailure("ViewController is not present on navigationStack")
                return
        }
        let innerIndex = viewControllers.firstIndex(of: viewController) ?? 0
        let _ = navigationController?.popToViewController(viewController, animated: animated)
        viewControllers.removeLast(viewControllers.count - 1 - innerIndex)
    }
    
    func popAll(animated: Bool = true) {
        guard
            let navigationStack = navigationController?.viewControllers,
            let firstManagedViewController = viewControllers.first,
            let index = navigationStack.firstIndex(of: firstManagedViewController),
            index > 0
        else {
            return
        }
        
        let previousIndex = index - 1
        let viewController = navigationStack[previousIndex]
        let _ = navigationController?.popToViewController(viewController, animated: animated)
        viewControllers = []
    }
    
    func changeWindowControllerTo(_ viewController: UIViewController) {
        window.rootViewController = viewController
        window.makeKeyAndVisible()
    }
    
    func backButtonPressed(sender: BaseViewController) {
        pop()
    }
    
    func willPreventPop(for sender: BaseViewController) -> Bool {
        return false
    }
}

// MARK: - Equtable implementation
extension Coordinator: Equatable {
    static func == (lhs: Coordinator, rhs: Coordinator) -> Bool {
        return lhs === rhs
    }
}

// MARK: - BaseCordinator implementation
extension Coordinator: BaseCoordinator {
    // Implemented in the main scope as swift cannot everride extensions yet.
}

// MARK: - FlowDelegate implementation
extension Coordinator: FlowDelegate {
    func coordinatorDidFinish(_ coordinator: Coordinator) {
        removeChildCoordinator(coordinator)
    }
}
