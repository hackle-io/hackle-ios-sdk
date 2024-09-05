//
//  InAppMessageUIContainerView.swift
//  Hackle
//
//  Created by yong on 2023/06/14.
//

import Foundation
import UIKit

extension HackleInAppMessageUI {
    class ContainerView: UIView {
        init() {
            super.init(frame: .zero)
        }

        required public init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // Layout

        private var layoutConstraintsInstalled = false

        override func layoutSubviews() {
            super.layoutSubviews()
            layoutConstraintsIfNeeded()
        }

        private func layoutConstraintsIfNeeded() {
            if layoutConstraintsInstalled {
                return
            }
            layoutConstraintsInstalled = true

            anchors.pin()

            superview?.layoutIfNeeded()
        }
    }
}
