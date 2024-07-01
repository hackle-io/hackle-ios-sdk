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
            titleLabel?.lineBreakMode = .byTruncatingTail
            titleLabel?.adjustsFontSizeToFitWidth = false
            layer.masksToBounds = true
            setContentCompressionResistancePriority(.required, for: .vertical)

            contentEdgeInsets = attributes.padding
            anchors.width.greaterThanOrEqual(attributes.minWidth).priority = .defaultHigh
            anchors.height.lessThanOrEqual(attributes.maxHeight).priority = .defaultHigh

            invalidateIntrinsicContentSize()
        }

        struct Attributes {
            var padding = UIEdgeInsets(top: 16, left: 8, bottom: 16, right: 8)
            var minWidth = 80.0
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

    class PositionalButtonView: UIButton {
        private let button: InAppMessage.Message.Button
        private let alignment: InAppMessage.Message.Alignment
        private let attributes: Attributes

        init(button: InAppMessage.Message.Button, alignment: InAppMessage.Message.Alignment, attributes: Attributes = .defaults) {
            self.button = button
            self.alignment = alignment
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
        }

        private func layout() {
            titleLabel?.lineBreakMode = .byTruncatingTail
            titleLabel?.adjustsFontSizeToFitWidth = false
            contentEdgeInsets = attributes.padding
            invalidateIntrinsicContentSize()
        }

        func align(to container: UIView) {
            switch (alignment.vertical, alignment.horizontal) {
            case (.top, .left):
                anchors.bottom.equal(container.anchors.top)
                anchors.left.pin(to: container)
            case (.top, .center):
                anchors.bottom.equal(container.anchors.top)
                anchors.centerX.pin(to: container)
            case (.top, .right):
                anchors.bottom.equal(container.anchors.top)
                anchors.right.pin(to: container)
            case (.middle, .left):
                anchors.centerY.pin(to: container)
                anchors.right.equal(container.anchors.left)
            case (.middle, .center):
                anchors.centerY.pin(to: container)
                anchors.centerX.pin(to: container)
            case (.middle, .right):
                anchors.centerY.pin(to: container)
                anchors.left.equal(container.anchors.right)
            case (.bottom, .left):
                anchors.top.equal(container.anchors.bottom)
                anchors.left.pin(to: container)
            case (.bottom, .center):
                anchors.top.equal(container.anchors.bottom)
                anchors.centerX.pin(to: container)
            case (.bottom, .right):
                anchors.top.equal(container.anchors.bottom)
                anchors.right.pin(to: container)
            }
        }

        struct Attributes {
            var padding = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            var font = UIFont.boldSystemFont(ofSize: 16)
            static var defaults = Self()
        }
    }
}
