import Foundation
import UIKit

extension HackleInAppMessageUI {

    class BannerView: UIView, InAppMessageView {
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
            contentView.addGestureRecognizer(tapContentViewGesture)
            contentView.isUserInteractionEnabled = true

            updateContent()
            layoutContent()

            alpha = 0
        }

        public required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        struct Attributes {
            var margin = UIEdgeInsets(top: 84, left: 32, bottom: 84, right: 32)
            var padding = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
            var spacing = 8.0
            var maxWidth = 340.0
            var height = 84.0
            var cornerRadius = 8.0
            var imageSize = CGSize(width: 60, height: 60)
            var imageCornerRadius = 4.0
            var font = UIFont.systemFont(ofSize: 14)
            var orientation = InAppMessage.Orientation.vertical
            var shadow = Shadow.inAppMessage
            static let defaults = Self()
        }

        private func updateContent() {
            bindImage()
            bindText()
        }

        private func bindImage() {
            guard let imageView = imageView, let image = context.message.image(orientation: attributes.orientation) else {
                return
            }
            imageView.loadImage(url: image.imagePath) {
                self.layoutContent()
            }
        }

        private func bindText() {
            guard let messageText = context.message.text, let textLabel = textLabel else {
                return
            }
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 4
            let text = NSMutableAttributedString(string: messageText.body.text, attributes: [
                .paragraphStyle: style,
                .font: attributes.font,
                .foregroundColor: messageText.body.color
            ])
            textLabel.attributedText = text
            textLabel.font = attributes.font
            textLabel.numberOfLines = 3
            textLabel.lineBreakMode = .byCharWrapping
            textLabel.sizeToFit()
        }

        // Layout

        private var contentConstraints: Constraints? = nil

        private func layoutContent() {
            frame = CGRect(x: 0, y: 0, width: 500, height: 500)
            contentConstraints?.deactivate()
            contentConstraints = Constraints {

                // Shadow
                layer.shadowColor = attributes.shadow.color.cgColor
                layer.shadowOffset = attributes.shadow.offset
                layer.shadowRadius = attributes.shadow.radius
                layer.shadowOpacity = attributes.shadow.opacity

                // ContentView
                contentView.anchors.pin()
                contentView.backgroundColor = context.message.backgroundColor
                contentView.layer.cornerRadius = attributes.cornerRadius
                contentView.stack.layoutMargins = attributes.padding
                contentView.stack.spacing = attributes.spacing

                // Image
                if let imageView = imageView {
                    imageView.anchors.size.equal(attributes.imageSize)
                    imageView.layer.cornerRadius = attributes.imageCornerRadius
                }

                // Text
                if let textLabel = textLabel {
                    textLabel.anchors.height.equal(attributes.imageSize.height)
                }

                // CloseButton
                if let closeButton = closeButton {
                    closeButton.anchors.size.equal(.init(width: 20, height: 20))
                    closeButton.titleLabel?.anchors.pin()
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
                anchors.height.equal(attributes.height)
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

        func dismiss() {
            if !self.presented {
                return
            }
            
            isUserInteractionEnabled = false
            UIView.animate(
                withDuration: 0.05,
                animations: {
                    self.presented = false
                },
                completion: { _ in
                    self.handle(event: .close)
                    self.didDismiss()
                }
            )
        }

        // Interactions

        lazy var tapContentViewGesture = UITapGestureRecognizer(target: self, action: #selector(tapContentView))

        @objc
        func tapContentView(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended,
                  let action = context.message.action
            else {
                return
            }
            handle(event: .action(action, .message))
        }

        // Views

        lazy var imageView: UIImageView? = {
            if context.message.images.isEmpty {
                return nil
            }
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.layer.masksToBounds = true
            return imageView
        }()

        lazy var textLabel: UILabel? = {
            if context.message.text == nil {
                return nil
            }
            let label = UILabel()
            label.adjustsFontForContentSizeCategory = true
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
            label.layer.masksToBounds = true
            return label
        }()

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
            button.titleLabel?.textAlignment = .right
            button.contentHorizontalAlignment = .right
            button.contentVerticalAlignment = .top
            return button
        }()

        lazy var contentView: StackView = {
            let view = StackView(
                arrangedSubviews: [
                    imageView,
                    textLabel,
                    closeButton
                ].compactMap {
                    $0
                }
            )

            view.stack.axis = .horizontal
            view.stack.distribution = .fill
            view.stack.alignment = .leading
            view.stack.isLayoutMarginsRelativeArrangement = true
            return view
        }()
    }
}
