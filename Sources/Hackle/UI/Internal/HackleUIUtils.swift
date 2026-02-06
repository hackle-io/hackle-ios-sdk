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
        // NOTE: app extension에서 항상 nil
        UIApplication.value(forKeyPath: #keyPath(UIApplication.shared)) as? UIApplication
    }

    static var interfaceOrientation: UIInterfaceOrientation {
        if let windowScene = activeWindowScene {
            return windowScene.interfaceOrientation
        } else {
            return .unknown
        }
    }

    static var activeWindowScene: UIWindowScene? {
        guard let application = application else {
            return nil
        }
        
        let windowScenes = application.connectedScenes.compactMap { $0 as? UIWindowScene }
        return windowScenes.first { $0.activationState == .foregroundActive } ?? windowScenes.first
    }

    static var keyWindow: UIWindow? {
        return activeWindowScene?.windows.first { window in
            window.isKeyWindow
        }
    }

    static var currentScreen: UIScreen {
        // NOTE: 앱에 scene이 연결되기 전에는 (ex. didFinishLaunchingWithOptions 시점) activeWindowScene이 nil
        //  currentScreen을 이용해서 sdk 초기화 시 화면 사이즈를 캐싱하는데, 이 때 UIScreen.main을 사용할 수 있음
        //  deprecate 되었지만 정상적인 값을 리턴해서 기존 로직 일단 유지
        return activeWindowScene?.screen ?? UIScreen.main
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
