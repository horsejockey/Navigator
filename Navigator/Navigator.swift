//
//  Navigator.swift
//  Navigator
//
//  Created by Matthew McArthur on 1/26/20.
//  Copyright © 2020 McArthur Labs. All rights reserved.
//

import Foundation
import UIKit
import Reactor

public protocol NavigatorViewState {
    func viewController() -> UIViewController
}

public protocol ViewControllerFactory {
    func viewController(viewState: NavigatorViewState) -> UIViewController
}

public final class Navigator<State, Event, Command> {
    
    private let window: UIWindow
    private let viewControllerFactory: ViewControllerFactory
    private let converter: (Command) -> NavigationCommand<Event, Command>?

    init(window: UIWindow, viewControllerFactory: ViewControllerFactory, converter: @escaping (Command) -> NavigationCommand<Event, Command>?) {
        self.window = window
        self.viewControllerFactory = viewControllerFactory
        self.converter = converter
    }
    
    public func commandProcessor(core: Core<State, Event, Command>, cmd: Command) {
        guard let command = converter(cmd) else { return }

        DispatchQueue.main.async {
            switch command {
            case .replaceRootRoute(let route):
                self.navigate(window: self.window, route: route)
            case .push(let item):
                self.push(window: self.window, item: item)
            case .replace(let item):
                self.replace(window: self.window, item: item)
            case .replaceNavViewStack(let items):
                self.replaceNavViewStack(window: self.window, items: items)
            case .pop:
                self.pop(window: self.window)
            case .popToViewController(let viewClass):
                self.popToViewController(window: self.window, viewClass: viewClass)
            case .popToRoot:
                self.popToRoot(window: self.window)
            case .modal(let item, let presentation):
                self.presentModal(window: self.window, item: item, presentation: presentation)
            case .dismissModal:
                self.dismissModal(window: self.window, completion: nil)
            case .dismissModalWithCompletion(let completion):
                self.dismissModal(window: self.window, completion: completion)
            case .alert(let alert, let filter):
                self.showAlert(window: self.window, info: alert, filter: filter, core: core)
            case .showHUD(let title, let description):
                self.showHUD(window: self.window, title: title, description: description)
            case .dismissHUD:
                self.dismissHUD(window: self.window)
            case .updateTabBarBadge(let index, let badgeValue):
                self.updateBarItemBadge(window: self.window, index: index, badge: badgeValue)
            }
        }
    }

    // MARK: - Helpers

    private func navigate(window: UIWindow, route: Route) {
        let root = createRoute(route: route)
        window.rootViewController = root

        UIView.transition(with: window, duration: TimeInterval(0.3), options: .transitionCrossDissolve, animations: {}, completion: nil)
    }

    private func push(window: UIWindow, item: NavigatorViewState) {
        let viewController = viewControllerFactory.viewController(viewState: item)
        window.topNavController()?.pushViewController(viewController, animated: true)
    }
    
    private func replace(window: UIWindow, item: NavigatorViewState) {
        let viewController = viewControllerFactory.viewController(viewState: item)
        let navController = window.topNavController()
        var viewControllers = navController?.viewControllers ?? []
        _ = viewControllers.popLast()
        viewControllers.append(viewController)
        window.topNavController()?.setViewControllers(viewControllers, animated: true)
    }
    
    private func replaceNavViewStack(window: UIWindow, items: [NavigatorViewState]) {
        let viewControllers = items.map { viewControllerFactory.viewController(viewState: $0) }
        window.topNavController()?.setViewControllers(viewControllers, animated: true)
    }

    private func pop(window: UIWindow) {
        window.topNavController()?.popViewController(animated: true)
    }

    private func popToViewController(window: UIWindow, viewClass: AnyClass) {
        guard let nav = window.topNavController() else { return }

        guard let viewController = nav.viewControllers.filter({ type(of: $0) == viewClass }).last else { return }

        nav.popToViewController(viewController, animated: true)
    }

    private func popToRoot(window: UIWindow) {
        window.topNavController()?.popToRootViewController(animated: true)
    }

    private func presentModal(window: UIWindow, item: NavigatorViewState, presentation: UIModalPresentationStyle) {
        let viewController = viewControllerFactory.viewController(viewState: item)

        let navController = UINavigationController(rootViewController: viewController)
        navController.modalPresentationStyle = presentation

        window.topViewController()?.showDetailViewController(navController, sender: nil)
    }

    private func dismissModal(window: UIWindow, completion: (() -> Void)? = nil) {
        window.topViewController()?.dismiss(animated: true, completion: completion)
    }

    private func showAlert(window: UIWindow, info: AlertInfo<Event, Command>, filter: ((UIViewController) -> Bool)?, core: Core<State, Event, Command>) {
        guard let viewController = window.topViewController() else {
            return NSLog("Couldn't find a suitable view controller to present the alert.")
        }
        if let filter = filter, filter(viewController) == false {
            return
        }

        let alert = UIAlertController(title: info.title, message: info.message, preferredStyle: .alert)

        if let attributedMessage = info.attributedMessage {
            alert.setValue(attributedMessage, forKey: "attributedMessage")
        }
        
        for action in info.actions {
            if let event = action.event {
                alert.addAction(UIAlertAction(title: action.text, style: action.style) { _ in
                    core.fire(event: event)
                })
            }else if let command = action.command {
                alert.addAction(UIAlertAction(title: action.text, style: action.style) { _ in
                    core.perform(command: command)
                })
            } else {
                alert.addAction(UIAlertAction(title: action.text, style: action.style, handler: nil))
            }
        }

        viewController.showDetailViewController(alert, sender: nil)
    }
    
    private func showHUD(window: UIWindow, title: String?, description: String?) {
        guard let visibleView = window.rootViewController?.view else { return }
        SimpleHUD.showHUDInView(view: visibleView, title: title, description: description)
    }
    
    private func dismissHUD(window: UIWindow) {
        guard let visibleView = window.rootViewController?.view else { return }
        SimpleHUD.removeHUDFromView(view: visibleView)
    }
    
    private func updateBarItemBadge(window: UIWindow, index: Int, badge: String?){
        guard let tabVC = window.rootViewController as? UITabBarController, index < (tabVC.tabBar.items?.count ?? 0) else { return }
        let tabItem = tabVC.tabBar.items?[index]
        tabItem?.badgeValue = badge
    }
    
    private func createRoute(route: Route) -> UIViewController {
        switch route {
        case .tab(let tabs, let selectedIndex):
            let viewControllers = tabs.map({ createRoute(route: $0) })
            let tabController = UITabBarController()
            tabController.setViewControllers(viewControllers, animated: false)
            tabController.selectedIndex = selectedIndex

            return tabController

        case .nav(let items):
            let viewControllers = items.map({ viewControllerFactory.viewController(viewState: $0) })
            let navController = UINavigationController()
            navController.viewControllers = viewControllers
            
            return navController

        case .view(let item):
            return viewControllerFactory.viewController(viewState: item)
        }
    }
}

public enum NavigationCommand<Event, Command> {
    case replaceRootRoute(Route)
    case push(NavigatorViewState)
    case replace(NavigatorViewState)
    case replaceNavViewStack([NavigatorViewState])
    case pop
    case popToViewController(AnyClass)
    case popToRoot
    case modal(NavigatorViewState, UIModalPresentationStyle)
    case dismissModal
    case dismissModalWithCompletion((()->Void)?)
    case alert(AlertInfo<Event, Command>, filter: ((UIViewController) -> Bool)? = nil)
    case showHUD(title: String? = nil, description: String? = nil)
    case dismissHUD
    case updateTabBarBadge(index: Int, badge: String?)
}

public struct AlertInfo<Event, Command> {
    fileprivate let title: String
    fileprivate let message: String?
    fileprivate let attributedMessage: NSAttributedString?
    fileprivate let actions: [AlertAction<Event, Command>]

    public init(title: String, message: String?, attributedMessage: NSAttributedString? = nil, primaryAction: AlertAction<Event, Command>, otherActions: [AlertAction<Event, Command>] = []) {
        self.title = title
        self.message = message
        self.attributedMessage = attributedMessage
        self.actions = [primaryAction] + otherActions
    }
}

public struct AlertAction<Event, Command> {
    public let text: String
    public let event: Event?
    public let command: Command?
    public let style: UIAlertAction.Style
}

public indirect enum Route {
    case tab(tabs: [Route], selectedTab: Int)
    case nav([NavigatorViewState])
    case view(NavigatorViewState)
}
