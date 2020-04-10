//
//  SimpleHUD.swift
//  tilt
//
//  Created by Matthew McArthur on 12/16/19.
//  Copyright © 2019 MySmartBlinds. All rights reserved.
//

import Foundation
import UIKit

public final class SimpleHUD {
    
    @discardableResult
    public static func showHUDInView(view: UIView, title: String? = nil, description: String? = nil, tag: Int = 1990) -> UIView {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.startAnimating()
        var views: [UIView] = []
        if let title = title {
            let titleLabel = UILabel()
            titleLabel.textAlignment = .center
            titleLabel.text = title
            titleLabel.textColor = .white
            titleLabel.numberOfLines = 0
            views.append(titleLabel)
        }
        views.append(spinner)
        if let description = description {
            let descriptionLabel = UILabel()
            descriptionLabel.textAlignment = .center
            descriptionLabel.text = description
            descriptionLabel.textColor = .white
            descriptionLabel.numberOfLines = 0
            views.append(descriptionLabel)
        }
        let stackView = UIStackView(arrangedSubviews: views)
        stackView.axis = .vertical
        
        let containerView = UIView()
        
        let backgroundView = UIView()
        backgroundView.addSubview(stackView)
        stackView.pinToSuperview(insets: UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16))
        containerView.addSubview(backgroundView)
        backgroundView.centerInSuperview()
        backgroundView.widthAnchor.constraint(equalToConstant: 220).isActive = true
        var backgroundColor: UIColor = .black
        backgroundColor = backgroundColor.withAlphaComponent(0.7)
        backgroundView.backgroundColor = backgroundColor
        backgroundView.layer.cornerRadius = 5
        backgroundView.layer.masksToBounds = true
        
        containerView.tag = tag
        view.addSubview(containerView)
        containerView.pinToSuperview()
        
        return containerView
    }
    
    
    public static func removeHUDFromView(view: UIView, tag: Int = 1990) {
        let hud = view.viewWithTag(tag)
        hud?.removeFromSuperview()
    }
}
