//
//  NavigatorExtensions.swift
//  Navigator
//
//  Created by Matthew McArthur on 1/26/20.
//  Copyright © 2020 McArthur Labs. All rights reserved.
//

import UIKit

extension UIWindow {

    public func topNavController() -> UINavigationController? {
        return rootViewController?.topViewController().navigationController
    }

    public func topViewController() -> UIViewController? {
        return topNavController()?.topViewController()
    }
}

extension UIViewController {

    public func topNavController() -> UINavigationController? {
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topNavController()
        }
        else if let nav = self as? UINavigationController {
            return nav
        }
        else {
            return nil
        }
    }

    public func topViewController() -> UIViewController {
        if let modal = presentedViewController {
            return modal.topViewController()
        }
        else if let nav = self as? UINavigationController {
            return nav.viewControllers.last?.topViewController() ?? self
        }
        else if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topViewController() ?? self
        }
        else {
            return self
        }
    }
    
    public func setBackButtonTitle(to title: String) {
        let barButtonItem = UIBarButtonItem(title: title, style: .plain, target: self, action: nil)
        self.navigationItem.backBarButtonItem = barButtonItem
    }
}

public let maxUIElementDimension: CGFloat = 10000

extension UIView {

    public func pinToSuperview(insets: UIEdgeInsets = UIEdgeInsets()) {
        guard let parent = superview else {
            NSLog("No parent view in `pinToSuperview`.")
            return
        }

        let views = ["view": self]
        let metrics = [
            "left": insets.left as AnyObject,
            "right": insets.right as AnyObject,
            "top": insets.top as AnyObject,
            "bottom": insets.bottom as AnyObject
        ]
        translatesAutoresizingMaskIntoConstraints = false
        parent.addConstraints(NSLayoutConstraint.visualConstraints(metrics: metrics, views: views, constraints: [
            "H:|-(left)-[view]-(right)-|",
            "V:|-(top)-[view]-(bottom)-|",
            ]))
    }

    public func centerInSuperview() {
        centerVerticallyInSuperview()
        centerHorizontallyInSuperview()
    }

    public func centerVerticallyInSuperview() {
        guard let parent = superview else {
            NSLog("No parent view in `centerHorizontallyInSuperview`.")
            return
        }

        translatesAutoresizingMaskIntoConstraints = false
        parent.addConstraint(NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: parent, attribute: .centerY, multiplier: 1, constant: 0))
    }

    public func centerHorizontallyInSuperview() {
        guard let parent = superview else {
            NSLog("No parent view in `centerHorizontallyInSuperview`.")
            return
        }

        translatesAutoresizingMaskIntoConstraints = false
        parent.addConstraint(NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: parent, attribute: .centerX, multiplier: 1, constant: 0))
    }

    public func constrain(toHeight height: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: height))
    }

    public func constrain(toWidth width: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width))
    }

    public func constrain(toSize size: CGSize) {
        constrain(toHeight: size.height)
        constrain(toWidth: size.width)
    }

    public func compressedHeightForWidth(width: CGFloat) -> CGFloat {
        let maxSize = CGSize(width: width, height: maxUIElementDimension)
        return systemLayoutSizeFitting(maxSize).height
    }

    class func fromNib<T : UIView>(_ nibNameOrNil: String? = nil) -> T? {
        var view: T?
        let name: String
        if let nibName = nibNameOrNil {
            name = nibName
        } else {
            // Most nibs are demangled by practice, if not, just declare string explicitly
            guard let demangledName = "\(T.self)".components(separatedBy: ".").last else {
                return view
            }
            name = demangledName
        }
        let nibViews = Bundle.main.loadNibNamed(name, owner: nil, options: nil)
        for v in nibViews ?? [] {
            if let tog = v as? T {
                view = tog
            }
        }
        return view
    }
}

extension NSLayoutConstraint {

    public class func visualConstraints(options: NSLayoutConstraint.FormatOptions = [], metrics: [String: AnyObject]? = nil, views: [String: AnyObject], constraints: [String]) -> [NSLayoutConstraint] {
        return constraints.flatMap { NSLayoutConstraint.constraints(withVisualFormat: $0, options: options, metrics: metrics, views: views) }
    }
}

