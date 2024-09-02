//
//  InAppMessageUIStackView.swift
//  Hackle
//
//  Created by yong on 2023/06/12.
//

import Foundation
import UIKit

extension HackleInAppMessageUI {
    class StackView: UIView {
        let stack = UIStackView()

        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(stack)
            layoutMargins = .zero
            stack.layoutMargins = .zero
            stack.anchors.pin()
        }

        convenience init(arrangedSubviews subviews: [UIView]) {
            self.init(frame: .zero)
            subviews.forEach(stack.addArrangedSubview)
        }

        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var intrinsicContentSize: CGSize {
            stack.intrinsicContentSize
        }
    }
}
