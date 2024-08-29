//
//  InAppMessageView.swift
//  Hackle
//
//  Created by yong on 2023/06/05.
//

import Foundation
import UIKit

protocol InAppMessageView: UIView {

    var context: InAppMessagePresentationContext { get }

    var presented: Bool { get }

    func willTransition(orientation: InAppMessage.Orientation)

    func present()

    func dismiss()
}


extension InAppMessageView {

    var controller: HackleInAppMessageUI.ViewController? {
        responders
            .lazy
            .compactMap {
                $0 as? HackleInAppMessageUI.ViewController
            }
            .first
    }

    func didDismiss() {
        guard let controller = controller,
              let ui = controller.ui
        else {
            return
        }

        removeFromSuperview()

        if #available(iOS 13.0, *) {
            ui.window?.windowScene = nil
        }
        ui.window = nil
    }

    func handle(event: InAppMessage.Event) {
        guard let controller = controller,
              let ui = controller.ui,
                let eventHandler = ui.eventHandler
        else {
            return
        }
        eventHandler.handle(view: self, event: event)
    }
}
