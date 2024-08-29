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
        
        override func viewDidLoad() {
            super.viewDidLoad()
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            self.ui?.delegate?.onWillOpen?(inAppMessage: self.context.inAppMessage)
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            if presented {
                return
            }

            view.addSubview(messageView)
            messageView.present()
            presented = true
            
            self.ui?.delegate?.onDidOpen?(inAppMessage: self.context.inAppMessage)
        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            self.ui?.delegate?.onWillClose?(inAppMessage: self.context.inAppMessage)
        }
        
        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            self.ui?.delegate?.onDidClose?(inAppMessage: self.context.inAppMessage)
        }

        // Orientation
        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
            coordinator.animate { context in
                self.messageView.willTransition(orientation: InAppMessage.Orientation(size: size))
            }
        }
    }
}
