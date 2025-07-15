//
//  HackleUserExplorerViewExt.swift
//  Hackle
//
//  Created by sungwoo.yeo on 7/15/25.
//

import UIKit
import Foundation

extension HackleUserExplorerView {
    func createWindow(floatingButtonView: UIView, level: UIWindow.Level = .normal + 1) -> UIWindow {
        let viewController = UIViewController()
        viewController.view.addSubview(floatingButtonView)
        
        let window: UIWindow
        if #available(iOS 13.0, *), let windowScene = UIUtils.activeWindowScene {
            window = PassthroughWindow(windowScene: windowScene)
        } else {
            window = PassthroughWindow(frame: UIScreen.main.bounds)
        }
        window.windowLevel = level
        window.rootViewController = viewController
        return window
    }
    
    fileprivate class PassthroughWindow: UIWindow {
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            let hitView = super.hitTest(point, with: event)
            if hitView === self.rootViewController?.view {
                return nil
            }
            return hitView
        }
    }
}
