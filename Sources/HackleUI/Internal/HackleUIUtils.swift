//
//  HackleUIUtils.swift
//  Hackle
//
//  Created by yong on 2023/06/12.
//

import Foundation
import UIKit


class UIUtils {

    static var application: UIApplication {
        UIApplication.shared
    }


    static var interfaceOrientation: UIInterfaceOrientation {
        if #available(iOS 13.0, *), let windowScene = activeWindowScene {
            return windowScene.interfaceOrientation
        }
        return application.statusBarOrientation
    }

    @available(iOS 13.0, *)
    static var activeWindowScene: UIWindowScene? {
        var windowScene: UIWindowScene? = nil
        var activeWindowScene: UIWindowScene? = nil

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
}
