import Foundation
import UIKit

extension HackleInAppMessageUI {
    class BottomSheetView: UIView, InAppMessageView {
        let context: InAppMessagePresentationContext
        private var attributes: Attributes

        init(context: InAppMessagePresentationContext, attributes: Attributes = .defaults) {
            self.context = context
            self.attributes = attributes
            super.init(frame: .zero)

            // Frame
            addSubview(frameView)
            frameView.backgroundColor = attributes.frameBackgroundColor
            frameView.addGestureRecognizer(tapBackgroundGesture)
            frameView.alpha = 0

            // Content
            addSubview(contentView)
            contentView.backgroundColor = context.message.backgroundColor

            layoutContent()
        }

        public required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        struct Attributes {
            var orientation = InAppMessage.Orientation.vertical
            var frameBackgroundColor = UIColor(hex: "#1c1c1c", alpha: 0.5)
            var maxWidth = 540.0
            var cornerRadius = 16.0
            var imageAspectRatio = CGSize(width: 300.0, height: 200.0)
            var buttonHeight = 44.0
            var buttonPadding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

            static let defaults = Self()
        }

        // Layout

        private var contentConstraints: Constraints? = nil

        private func layoutContent() {
            contentConstraints?.deactivate()
            contentConstraints = Constraints {

                // ContentView
                if #available(iOS 11.0, *) {
                    contentView.layer.cornerRadius = attributes.cornerRadius
                    contentView.layer.maskedCorners = CACornerMask(arrayLiteral: .layerMinXMinYCorner, .layerMaxXMinYCorner)
                }
                contentView.stack.layoutMargins = .zero
                contentView.anchors.centerX.pin()
                contentView.anchors.width.lessThanOrEqual(attributes.maxWidth)
                contentView.anchors.pin(axis: .horizontal, priority: .required - 1)

                // Image
                if let imageContainer = imageContainer {
                    imageContainer.anchors.pin(axis: .horizontal)
                    imageContainer.anchors.size.aspectRatio(attributes.imageAspectRatio)
                }

                // Buttons
                if let buttonContainer = buttonContainer {
                    contentView.stack.isLayoutMarginsRelativeArrangement = true
                    buttonContainer.anchors.pin(axis: .horizontal)
                    buttonContainer.anchors.height.equal(attributes.buttonHeight)

                    if let leftButton = leftButton {
                        leftButton.anchors.leading.pin()
                        leftButton.anchors.height.equal(attributes.buttonHeight)
                        leftButton.anchors.centerY.pin()
                    }

                    if let rightButton = rightButton {
                        rightButton.anchors.trailing.pin()
                        rightButton.anchors.height.equal(attributes.buttonHeight)
                        rightButton.anchors.centerY.pin()
                    }
                }

                // CloseButton
                if let closeButton = closeButton {
                    closeButton.anchors.size.equal(.init(width: 52, height: 52))
                    closeButton.anchors.top.pin()
                    closeButton.anchors.trailing.pin()
                }
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            layoutFrameIfNeeded()
        }

        private var frameConstraintsInstalled = false
        private var contentViewConstraint: NSLayoutConstraint!

        private func layoutFrameIfNeeded() {
            guard let superview = superview, !frameConstraintsInstalled else {
                return
            }
            frameConstraintsInstalled = true

            layoutMargins = .zero
            Constraints {
                anchors.pin()
                frameView.anchors.pin()
                contentViewConstraint = contentView.anchors.bottom.pin()
                contentView.anchors.top.equal(anchors.bottom).priority = .defaultLow
            }

            contentViewConstraint.isActive = presented

            setNeedsLayout()
            superview.layoutIfNeeded()
        }

        // Presentation

        public var presented: Bool = false {
            didSet {
                if presented {
                    frameView.alpha = 1
                    contentViewConstraint.isActive = true
                } else {
                    frameView.alpha = 0
                    contentViewConstraint.isActive = false
                }
            }
        }

        func present() {
            willPresent()
            layoutFrameIfNeeded()

            UIView.performWithoutAnimation {
                superview?.layoutIfNeeded()
            }

            window?.makeKey()

            UIView.animate(
                withDuration: 0.3,
                animations: {
                    self.presented = true
                    self.superview?.layoutIfNeeded()
                },
                completion: { _ in
                    self.handle(event: .impression)
                    self.didPresent()
                }
            )
        }

        func dismiss() {
            if !self.presented {
                return
            }

            willDismiss()

            isUserInteractionEnabled = false
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    self.presented = false
                    self.superview?.layoutIfNeeded()
                },
                completion: { _ in
                    self.handle(event: .close)
                    self.didDismiss()
                }
            )
        }

        // Interactions

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

        @objc func tapBackground(_ gesture: UITapGestureRecognizer) {
            guard case .ended = gesture.state else {
                return
            }
            dismiss()
        }

        // Views

        lazy var closeButton: UIButton? = {
            guard let closeButton = context.message.closeButton else {
                return nil
            }

            if context.message.images(orientation: attributes.orientation).count > 1 {
                return nil
            }

            let view = UIButton(type: .custom)
            view.setTitle("✕", for: .normal)
            view.setTitleColor(closeButton.textColor, for: .normal)
            view.titleLabel?.font = .systemFont(ofSize: 20)
            view.onClick { [weak self] in
                self?.handle(event: .closeButtonAction(action: closeButton.action))
            }
            return view
        }()

        lazy var imageContainer: ImageContainerView? = {
            let items = context.message.imageItems(orientation: attributes.orientation)
            if items.isEmpty {
                return nil
            }
            let attributes = ImageContainerView.Attributes(autoScrollInterval: context.message.imageAutoScroll?.interval)
            let view = ImageContainerView(items: items, attributes: attributes) { [weak self] event in
                self?.handle(event: event)
            }
            return view
        }()

        lazy var buttonContainer: UIView? = {
            let buttons = context.message.innerButtons
            if buttons.isEmpty {
                return nil
            }

            let view = UIView()
            if let leftButton = leftButton {
                view.addSubview(leftButton)
            }
            if let rightButton = rightButton {
                view.addSubview(rightButton)
            }
            return view
        }()

        lazy var leftButton: PositionalButtonView? = {
            guard let button = context.message.buttonOrNil(horizontal: .left, vertical: .bottom) else {
                return nil
            }

            var attrs = PositionalButtonView.Attributes.defaults
            attrs.font = .systemFont(ofSize: 14)
            attrs.padding = attributes.buttonPadding
            let view = PositionalButtonView(button: button.button, alignment: button.alignment, attributes: attrs)
            view.onClick { [weak self] in
                self?.handle(event: .buttonAction(action: button.button.action, button: button.button))
            }
            return view
        }()

        lazy var rightButton: PositionalButtonView? = {
            guard let button = context.message.buttonOrNil(horizontal: .right, vertical: .bottom) else {
                return nil
            }
            var attrs = PositionalButtonView.Attributes.defaults
            attrs.font = .systemFont(ofSize: 14)
            attrs.padding = attributes.buttonPadding
            let view = PositionalButtonView(button: button.button, alignment: button.alignment, attributes: attrs)
            view.onClick { [weak self] in
                self?.handle(event: .buttonAction(action: button.button.action, button: button.button))
            }
            return view
        }()

        lazy var contentView: StackView = {
            let view = StackView(arrangedSubviews: [imageContainer, buttonContainer].compactMap({ $0 }))
            view.stack.axis = .vertical
            view.stack.distribution = .fill
            view.layer.masksToBounds = true
            if let closeButton = closeButton {
                view.addSubview(closeButton)
            }
            return view
        }()

        lazy var frameView: UIView = UIView()
    }
}
