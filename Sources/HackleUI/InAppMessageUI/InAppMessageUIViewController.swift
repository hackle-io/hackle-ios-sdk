//
//  InAppMessageUIViewController.swift
//  Hackle
//
//  Created by yong on 2023/06/05.
//

import Foundation
import UIKit

extension HackleInAppMessageUI {

    class ViewController: UIViewController {
        var context: InAppMessageContext
        var messageView: InAppMessageView
        var containerView: ContainerView
        weak var ui: HackleInAppMessageUI?

        private var presented: Bool = false

        init(
            ui: HackleInAppMessageUI,
            context: InAppMessageContext,
            messageView: InAppMessageView
        ) {
            self.ui = ui
            self.context = context
            self.messageView = messageView
            self.containerView = .init()

            super.init(nibName: nil, bundle: nil)
        }

        required public init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - LifeCycle

        override func loadView() {
            self.view = containerView
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            if presented {
                return
            }

            view.addSubview(messageView)
            messageView.present()
            presented = true
        }

        // MARK: - Orientation

//        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
//            context.message.supportedInterfaceOrientations
//        }

        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            Log.debug("ViewController.viewWillTransition(\(size))")
            super.viewWillTransition(to: size, with: coordinator)
            coordinator.animate { context in
                self.messageView.willTransition(orientation: InAppMessage.Orientation(size: size))
            }
        }
    }
}
