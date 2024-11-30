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
        var context: InAppMessagePresentationContext
        var messageView: InAppMessageView
        var containerView: ContainerView
        weak var ui: HackleInAppMessageUI?

        private var presented: Bool = false

        init(
            ui: HackleInAppMessageUI,
            context: InAppMessagePresentationContext,
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

        // LifeCycle
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

        // Orientation
        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
            coordinator.animate { context in
                self.messageView.dismiss()
            }
        }
    }
}
