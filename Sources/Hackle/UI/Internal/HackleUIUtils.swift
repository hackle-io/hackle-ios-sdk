//
//  HackleUIUtils.swift
//  Hackle
//
//  Created by yong on 2023/06/12.
//

import Foundation
import UIKit


class UIUtils {

    static var application: UIApplication? {
        UIApplication.value(forKeyPath: #keyPath(UIApplication.shared)) as? UIApplication
    }

    static var interfaceOrientation: UIInterfaceOrientation {
        if #available(iOS 13.0, *), let windowScene = activeWindowScene {
            return windowScene.interfaceOrientation
        }

        if let application = application {
            return application.statusBarOrientation
        } else {
            return .unknown
        }
    }

    @available(iOS 13.0, *)
    static var activeWindowScene: UIWindowScene? {
        var windowScene: UIWindowScene? = nil
        var activeWindowScene: UIWindowScene? = nil

        guard let application = application else {
            return nil
        }

        for scene in application.connectedScenes {
            guard let scene = scene as? UIWindowScene else {
                continue
            }
            windowScene = scene
            if scene.activationState == .foregroundActive {
                activeWindowScene = windowScene
            }
        }

        return activeWindowScene ?? windowScene
    }

    static var keyWindow: UIWindow? {
        if #available(iOS 13, *) {
            return application?.windows.first { window in
                window.isKeyWindow
            }
        } else {
            return application?.keyWindow
        }
    }

    static var topViewController: UIViewController? {
        var top = keyWindow?.rootViewController
        while true {
            if let nav = top as? UINavigationController {
                top = nav.visibleViewController
            } else if let tab = top as? UITabBarController {
                top = tab.selectedViewController
            } else if let presented = top?.presentedViewController {
                top = presented
            } else {
                break
            }
        }
        return top
    }
}
