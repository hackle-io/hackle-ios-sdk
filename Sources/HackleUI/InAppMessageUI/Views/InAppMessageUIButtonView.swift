//
//  InAppMessageButtonView.swift
//  Hackle
//
//  Created by yong on 2023/06/12.
//

import Foundation
import UIKit

extension HackleInAppMessageUI {

    class ButtonView: UIButton {

        private let button: InAppMessage.Message.Button
        private let attributes: Attributes

        init(button: InAppMessage.Message.Button, attributes: Attributes = .defaults) {
            self.button = button
            self.attributes = attributes
            super.init(frame: .zero)

            content()
            layout()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func content() {
            setTitle(button.text, for: .normal)
            setTitleColor(button.textColor, for: .normal)
            titleLabel?.font = attributes.font
            backgroundColor = button.backgroundColor
            layer.borderColor = button.borderColor.cgColor
            layer.borderWidth = attributes.borderWidth
            layer.cornerRadius = attributes.cornerRadius
        }

        private func layout() {
            titleLabel?.adjustsFontForContentSizeCategory = true
            titleLabel?.adjustsFontSizeToFitWidth = true
            layer.masksToBounds = true
            setContentCompressionResistancePriority(.required, for: .vertical)

            contentEdgeInsets = attributes.padding
            anchors.width.greaterThanOrEqual(attributes.minWidth).priority = .defaultHigh
            anchors.height.lessThanOrEqual(attributes.maxHeight).priority = .defaultHigh

            invalidateIntrinsicContentSize()
        }

        struct Attributes {
            var padding = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
            var minWidth =  80.0
            var maxHeight = 56.0
            var borderWidth = 1.0
            var cornerRadius = 4.0
            var font = UIFont.boldSystemFont(ofSize: 16)
            static var defaults = Self()
        }

        override var intrinsicContentSize: CGSize {
            CGSize(
                width: max(super.intrinsicContentSize.width, attributes.minWidth),
                height: min(super.intrinsicContentSize.height, attributes.maxHeight)
            )
        }

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            content()
            layout()
        }
    }
}
