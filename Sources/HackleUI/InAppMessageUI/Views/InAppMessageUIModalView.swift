//
//  InAppMessageUiModalView.swift
//  Hackle
//
//  Created by yong on 2023/06/05.
//

import Foundation
import UIKit

extension HackleInAppMessageUI {

    class ModalView: UIView, InAppMessageView {

        let context: InAppMessageContext
        private var attributes: Attributes

        init(context: InAppMessageContext, attributes: Attributes = .defaults) {
            self.context = context
            self.attributes = attributes
            super.init(frame: .zero)

            addSubview(contentView)
            updateContent()
            layoutContent()

            addGestureRecognizer(tapBackgroundGesture)
            backgroundColor = .black.withAlphaComponent(0.3)
            alpha = 0
        }

        public required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        struct Attributes {
            var margin = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
            var padding = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            var minWidth = 320.0
            var maxWidth = 450.0
            var maxHeight = 720.0
            var cornerRadius = 8.0
            var spacing = 16.0
            var orientation = InAppMessage.Orientation.vertical

            static let defaults = Self()
        }

        // MARK: - Apply Content

        private func updateContent() {
            contentView.backgroundColor = context.message.backgroundColor
            bindImage()
            bindText()
        }

        private func bindImage() {
            guard let imageView = imageView,
                  let image = context.message.image(orientation: attributes.orientation)
            else {
                return
            }
            imageView.loadImage(url: image.imagePath) {
                self.layoutContent()
            }
            imageView.addGestureRecognizer(tapImageViewGesture)
            imageView.isUserInteractionEnabled = true
        }

        private func bindText() {
            guard let messageText = context.message.text, let textView = textView else {
                return
            }
            let text = NSMutableAttributedString()
            text.append(messageText.title.attributed(font: .boldSystemFont(ofSize: 20), color: messageText.title.color))
            text.append(NSAttributedString(string: "\n"))
            text.append(NSAttributedString(string: "\n"))
            text.append(messageText.body.attributed(font: .systemFont(ofSize: 16), color: messageText.body.color))

            textView.attributedText = text
        }

        private func layoutContent() {
            layoutMargins = attributes.margin

            // ContentView
            contentView.stack.layoutMargins = .zero
            contentView.layer.cornerRadius = attributes.cornerRadius
            contentView.stack.spacing = attributes.spacing
            // - width
            contentView.anchors.width.lessThanOrEqual(attributes.maxWidth)
            contentView.anchors.width.greaterThanOrEqual(attributes.minWidth).priority = .required - 1
            contentView.anchors.leading.greaterThanOrEqual(layoutMarginsGuide.anchors.leading, constant: attributes.margin.left).priority = .required - 1
            contentView.anchors.trailing.lessThanOrEqual(layoutMarginsGuide.anchors.trailing, constant: attributes.margin.left).priority = .required - 1
            contentView.anchors.centerX.align()
            // - height
            contentView.anchors.height.lessThanOrEqual(attributes.maxHeight)
            contentView.anchors.top.greaterThanOrEqual(anchors.top, constant: attributes.margin.top).priority = .required - 1
            contentView.anchors.bottom.lessThanOrEqual(anchors.bottom, constant: attributes.margin.bottom).priority = .required - 1
            contentView.anchors.centerY.align()

            // ImageView
            if let imageView = imageView, let image = imageView.image {
                let size = image.size
                let ratio = size.width / size.height
                imageView.anchors.width.equal(imageView.anchors.height.multiply(by: ratio))
            }

            // TextView
            if let textView = textView, let textContainer = textContainer {
                textContainer.layoutMargins = .init(top: 0, left: 16, bottom: 0, right: 16)
                textView.textAlignment = .center
                textView.anchors.pin(to: textContainer.layoutMarginsGuide)
            }

            // ButtonView
            if let buttonContainer = buttonContainer {
                buttonContainer.stack.layoutMargins = .init(top: 0, left: 16, bottom: 16, right: 16)
            }

            // CloseButton
            if let closeButton = closeButton {
                closeButton.anchors.height.equal(closeButton.anchors.width)
                closeButton.anchors.top.pin()
                closeButton.anchors.trailing.pin()
            }

            setNeedsLayout()
            layoutIfNeeded()
        }

        // MARK: - Orientation

        func willTransition(orientation: InAppMessage.Orientation) {
            guard context.message.supports(orientation: orientation) else {
                dismiss()
                return
            }

            attributes.orientation = orientation
            updateContent()
            layoutContent()
        }

        // MARK - Layout

        private var layoutConstraintsInstalled = false

        override func layoutSubviews() {
            super.layoutSubviews()
            layoutConstraintsIfNeeded()
        }

        private func layoutConstraintsIfNeeded() {
            guard let superview = superview, !layoutConstraintsInstalled else {
                return
            }
            layoutConstraintsInstalled = true

            anchors.pin()

            setNeedsLayout()
            superview.layoutIfNeeded()
        }

        // MARK: - Presentation

        public var presented: Bool = false {
            didSet {
                alpha = presented ? 1 : 0
            }
        }

        @objc
        func present() {
            layoutConstraintsIfNeeded()

            UIView.performWithoutAnimation {
                superview?.layoutIfNeeded()
            }

            window?.makeKey()
            UIView.animate(
                withDuration: 0,
                animations: { self.presented = true },
                completion: { _ in
                    self.track(event: .impression)
                }
            )
        }

        @objc
        func dismiss() {
            isUserInteractionEnabled = false
            UIView.animate(
                withDuration: 0,
                animations: { self.presented = false },
                completion: { _ in
                    self.track(event: .close)
                    self.didDismiss()
                }
            )
        }

        // MARK: - Interactions

        class TapGestureDelegate: NSObject, UIGestureRecognizerDelegate {
            private let contentView: UIView

            init(contentView: UIView) {
                self.contentView = contentView
                super.init()
            }

            func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
                guard touch.view?.isDescendant(of: contentView) == false else {
                    return false
                }
                return true
            }
        }

        lazy var tapBackgroundGestureDelegate = TapGestureDelegate(contentView: contentView)

        lazy var tapBackgroundGesture: UITapGestureRecognizer = {
            let tapBackgroundGesture = UITapGestureRecognizer(target: self, action: #selector(tapBackground))
            tapBackgroundGesture.delegate = tapBackgroundGestureDelegate
            return tapBackgroundGesture
        }()

        @objc
        func tapBackground(_ gesture: UITapGestureRecognizer) {
            guard case .ended = gesture.state else {
                return
            }
            dismiss()
        }

        lazy var tapImageViewGesture = UITapGestureRecognizer(target: self, action: #selector(tapImageView))

        @objc
        func tapImageView(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended,
                  let image = context.message.image(orientation: attributes.orientation),
                  let action = image.action
            else {
                return
            }

            track(event: .action(action, .image))
            handleAction(action: action)
        }


        // MARK: - Views

        lazy var closeButton: UIButton? = {
            guard let closeButton = context.message.closeButton else {
                return nil
            }

            let button = UIButton(type: .custom)
            button.setTitle("✕", for: .normal)
            button.setTitleColor(closeButton.textColor, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 22)
            button.onClick { [weak self] in
                self?.track(event: .action(closeButton.action, .xButton))
                self?.handleAction(action: closeButton.action)

            }
            return button
        }()

        lazy var imageView: UIImageView? = {
            if context.message.images.isEmpty {
                return nil
            }
            let imageView = UIImageView()
            imageView.contentMode = .scaleToFill
            return imageView
        }()

        lazy var textView: UITextView? = {
            if context.message.text == nil {
                return nil
            }
            let textView = UITextView()
            textView.backgroundColor = .clear
            textView.isEditable = false
            textView.isSelectable = false
            textView.isScrollEnabled = false
            textView.setContentCompressionResistancePriority(.required, for: .vertical)
            textView.setContentHuggingPriority(.required, for: .vertical)
            textView.adjustsFontForContentSizeCategory = true
            textView.textAlignment = .center
            return textView
        }()

        lazy var textContainer: UIScrollView? = {
            guard let textView = textView else {
                return nil
            }
            let container = UIScrollView()
            container.addSubview(textView)
            return container
        }()

        lazy var buttonContainer: StackView? = {
            let buttons = context.message.buttons
            if buttons.isEmpty {
                return nil
            }
            let buttonViews = buttons.map { it in
                let button = ButtonView(button: it)
                button.onClick { [weak self] in
                    self?.track(event: .action(it.action, .button, it.text))
                    self?.handleAction(action: it.action)
                }
                return button
            }

            let container = StackView(arrangedSubviews: buttonViews)
            container.stack.distribution = .fillEqually
            container.stack.alignment = .center
            container.stack.axis = .horizontal
            container.stack.spacing = 8
            container.stack.isLayoutMarginsRelativeArrangement = true
            container.isHidden = false
            return container
        }()

        lazy var contentView: StackView = {
            let view = StackView(
                arrangedSubviews: [
                    imageView,
                    textContainer,
                    buttonContainer
                ].compactMap {
                    $0
                }
            )
            view.stack.axis = .vertical
            view.stack.distribution = .fill
            view.stack.isLayoutMarginsRelativeArrangement = true
            view.layer.masksToBounds = true
            if let closeButton = closeButton {
                view.addSubview(closeButton)
            }
            return view
        }()
    }
}
