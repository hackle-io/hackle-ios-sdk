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

            // Image
            imageView?.addGestureRecognizer(tapImageViewGesture)
            imageView?.isUserInteractionEnabled = true

            updateContent()
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

        func updateContent() {
            guard let imageView = imageView, let image = context.message.image(orientation: attributes.orientation) else {
                return
            }
            imageView.loadImage(url: image.imagePath) {
                self.layoutContent()
            }
        }

        // Layout

        private var contentConstraints: Constraints? = nil

        private func layoutContent() {
            frame = CGRect(x: 0, y: 0, width: 500, height: 500)
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

                // ImageView
                if let imageView = imageView {
                    imageView.anchors.pin(axis: .horizontal)
                    if let image = imageView.image {
                        imageView.anchors.size.aspectRatio(image.size)
                    } else {
                        imageView.anchors.size.aspectRatio(attributes.imageAspectRatio)
                    }
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

            setNeedsLayout()
            layoutIfNeeded()
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

        // Orientation

        func willTransition(orientation: InAppMessage.Orientation) {
            guard context.inAppMessage.supports(orientation: orientation) else {
                dismiss()
                return
            }

            attributes.orientation = orientation
            updateContent()
            layoutContent()
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
                }
            )
        }

        func dismiss() {
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
        
        func close() {
            if self.presented {
                self.dismiss()
            }
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

        lazy var tapImageViewGesture = UITapGestureRecognizer(target: self, action: #selector(tapImageView))

        @objc func tapImageView(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended,
                    let image = context.message.image(orientation: attributes.orientation),
                  let action = image.action else {
                return
            }

            handle(event: .action(action, .image))
        }

        // Views

        lazy var closeButton: UIButton? = {
            guard let closeButton = context.message.closeButton else {
                return nil
            }

            let view = UIButton(type: .custom)
            view.setTitle("✕", for: .normal)
            view.setTitleColor(closeButton.textColor, for: .normal)
            view.titleLabel?.font = .systemFont(ofSize: 20)
            view.onClick { [weak self] in
                self?.handle(event: .action(closeButton.action, .xButton))
            }
            return view
        }()

        lazy var imageView: UIImageView? = {
            if context.message.images.isEmpty {
                return nil
            }
            let view = UIImageView()
            view.contentMode = .scaleToFill
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
                self?.handle(event: .action(button.button.action, .button, button.button.text))
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
                self?.handle(event: .action(button.button.action, .button, button.button.text))
            }
            return view
        }()

        lazy var contentView: StackView = {
            let view = StackView(arrangedSubviews: [imageView, buttonContainer].compactMap({ $0 }))
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
