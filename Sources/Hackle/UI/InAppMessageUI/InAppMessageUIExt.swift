//
//  InAppMessageUIExt.swift
//  Hackle
//
//  Created by yong on 2023/06/12.
//

import Foundation
import UIKit

extension HackleInAppMessageUI {

    func createMessageView(context: InAppMessagePresentationContext) -> InAppMessageView? {
        switch context.message.layout.displayType {
        case .modal:
            let attributes = ModalView.Attributes(orientation: InAppMessage.Orientation(UIUtils.interfaceOrientation))
            return ModalView(context: context, attributes: attributes)
        }
    }

    func createWindow(viewController: ViewController) -> Window {
        let window: Window
        if #available(iOS 13.0, *), let windowScene = UIUtils.activeWindowScene {
            window = Window(windowScene: windowScene)
        } else {
            window = Window(frame: UIScreen.main.bounds)
        }
        window.accessibilityViewIsModal = true
        window.windowLevel = .normal
        window.rootViewController = viewController
        return window
    }
}
