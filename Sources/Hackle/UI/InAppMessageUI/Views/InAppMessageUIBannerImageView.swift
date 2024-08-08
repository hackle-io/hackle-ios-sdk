import Foundation
import UIKit

extension HackleInAppMessageUI {

    class BannerImageView: UIView, InAppMessageView {
        let context: InAppMessagePresentationContext
        private let alignment: InAppMessage.Message.Alignment
        private var attributes: Attributes

        init(
            context: InAppMessagePresentationContext,
            alignment: InAppMessage.Message.Alignment,
            attributes: Attributes = .defaults
        ) {
            self.context = context
            self.alignment = alignment
            self.attributes = attributes
            super.init(frame: .zero)

            addSubview(contentView)

            imageView?.addGestureRecognizer(tapImageViewGesture)
            imageView?.isUserInteractionEnabled = true

            updateContent()
            layoutContent()

            alpha = 0
        }

        public required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        struct Attributes {
            var margin = UIEdgeInsets(top: 84, left: 32, bottom: 84, right: 32)
            var maxWidth = 340.0
            var minHeight = 84.0
            var cornerRadius = 8.0
            var orientation = InAppMessage.Orientation.vertical
            var shadow = Shadow.inAppMessage
            static let defaults = Self()
        }

        private func updateContent() {
            bindImage()
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
        }

        // Layout

        private var contentConstraints: Constraints? = nil

        private func layoutContent() {
            contentConstraints?.deactivate()
            contentConstraints = Constraints {

                // Shadow
                layer.shadowColor = attributes.shadow.color.cgColor
                layer.shadowOffset = attributes.shadow.offset
                layer.shadowRadius = attributes.shadow.radius
                layer.shadowOpacity = attributes.shadow.opacity

                // ContentView
                contentView.anchors.pin()
                contentView.layer.cornerRadius = attributes.cornerRadius
                contentView.stack.layoutMargins = .zero
                contentView.stack.spacing = .zero

                // ImageView
                if let imageView = imageView, let image = imageView.image {
                    let size = image.size
                    let ratio = size.width / size.height
                    imageView.anchors.width.equal(imageView.anchors.height.multiply(by: ratio))
                }

                // CloseButton
                if let closeButton = closeButton {
                    closeButton.anchors.height.equal(closeButton.anchors.width)
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

        private func layoutFrameIfNeeded() {
            guard let superview = superview, !frameConstraintsInstalled else {
                return
            }
            frameConstraintsInstalled = true

            Constraints {
                // - width
                anchors.width.lessThanOrEqual(attributes.maxWidth)
                anchors.width.equal(attributes.maxWidth).priority = .required - 1
                anchors.lessThanOrEqual(insets: attributes.margin, axis: .horizontal, priority: .required - 1)
                anchors.centerX.align()

                // - height
                anchors.height.greaterThanOrEqual(attributes.minHeight)
                switch alignment.vertical {
                case .top:
                    anchors.top.pin(inset: attributes.margin.top)
                    break
                case .middle:
                    anchors.centerY.align()
                    break
                case .bottom:
                    anchors.bottom.pin(inset: attributes.margin.bottom)
                    break
                }
            }
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
                alpha = presented ? 1 : 0
            }
        }

        @objc
        func present() {
            layoutFrameIfNeeded()

            UIView.performWithoutAnimation {
                superview?.layoutIfNeeded()
            }

            window?.makeKey()
            UIView.animate(
                withDuration: 0.05,
                animations: { self.presented = true },
                completion: { _ in
                    self.handle(event: .impression)
                }
            )
        }

        @objc
        func dismiss() {
            isUserInteractionEnabled = false
            UIView.animate(
                withDuration: 0.05,
                animations: { self.presented = false },
                completion: { _ in
                    self.handle(event: .close)
                    self.didDismiss()
                }
            )
        }

        // Interactions

        lazy var tapImageViewGesture = UITapGestureRecognizer(target: self, action: #selector(tapImageView))

        @objc
        func tapImageView(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended,
                  let action = context.message.action
            else {
                return
            }
            handle(event: .action(action, .message))
        }

        // Views

        lazy var closeButton: UIButton? = {
            guard let closeButton = context.message.closeButton else {
                return nil
            }

            let button = UIButton(type: .custom)
            button.setTitle("✕", for: .normal)
            button.setTitleColor(closeButton.textColor, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 20)
            button.onClick { [weak self] in
                self?.handle(event: .action(closeButton.action, .xButton))

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

        lazy var contentView: StackView = {
            let view = StackView(
                arrangedSubviews: [imageView].compactMap {
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
