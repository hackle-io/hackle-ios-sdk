import Foundation
import UIKit

extension HackleInAppMessageUI {
    class ModalView: UIView, InAppMessageView {
        let context: InAppMessagePresentationContext
        private var attributes: Attributes

        init(context: InAppMessagePresentationContext, attributes: Attributes = .defaults) {
            self.context = context
            self.attributes = attributes
            super.init(frame: .zero)

            // Frame (outside of modal)
            backgroundColor = attributes.backgroundColor
            addGestureRecognizer(tapBackgroundGesture)
            alpha = 0

            // Content (inside of modal)
            addSubview(contentView)
            contentView.backgroundColor = messageBackgroundColor

            // Image
            imageView?.addGestureRecognizer(tapImageViewGesture)
            imageView?.isUserInteractionEnabled = true

            // OuterButtons
            for button in outerButtons {
                addSubview(button)
            }

            updateContent()
            layoutContent()
        }

        public required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        struct Attributes {
            var margin = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
            var minWidth = 320.0
            var maxWidth = 380.0
            var maxHeight = 720.0
            var cornerRadius = 8.0
            var spacing = 0.0
            var orientation = InAppMessage.Orientation.vertical
            var backgroundColor = UIColor(hex: "#1c1c1c", alpha: 0.5)
            var shadow = Shadow.inAppMessage

            static let defaults = Self()
        }

        var imageAspectRatio: CGSize? {
            switch context.message.layout.layoutType {
            case .none, .textOnly:
                return nil
            case .imageText:
                return .init(width: 290, height: 100)
            case .imageOnly, .image:
                switch attributes.orientation {
                case .vertical:
                    return .init(width: 200, height: 300)
                case .horizontal:
                    return .init(width: 300, height: 200)
                }
            }
        }

        var messageBackgroundColor: UIColor? {
            switch context.message.layout.layoutType {
            case .none, .image:
                return nil
            case .textOnly, .imageText, .imageOnly:
                return context.message.backgroundColor
            }
        }

        // Apply Content

        private func addView() {
            addSubview(contentView)
            for button in outerButtons {
                addSubview(button)
            }
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
            guard let messageText = context.message.text, let textView = textView else {
                return
            }
            let text = NSMutableAttributedString()
            text.append(messageText.title.attributed(font: .boldSystemFont(ofSize: 20), color: messageText.title.color))
            text.append(NSAttributedString(string: "\n\n"))
            text.append(messageText.body.attributed(font: .systemFont(ofSize: 16), color: messageText.body.color))

            textView.attributedText = text
        }

        // Layout

        private var contentConstraints: Constraints? = nil

        private func layoutContent() {
            layoutMargins = attributes.margin

            contentConstraints?.deactivate()
            contentConstraints = Constraints {

                // Shadow
                layer.shadowColor = attributes.shadow.color.cgColor
                layer.shadowOffset = attributes.shadow.offset
                layer.shadowRadius = attributes.shadow.radius
                layer.shadowOpacity = attributes.shadow.opacity

                // ContentView
                contentView.stack.layoutMargins = .zero
                contentView.layer.cornerRadius = attributes.cornerRadius
                contentView.stack.spacing = attributes.spacing
                // - width
                contentView.anchors.width.lessThanOrEqual(attributes.maxWidth)
                contentView.anchors.width.greaterThanOrEqual(attributes.minWidth).priority = .required - 1
                contentView.anchors.pin(to: layoutMarginsGuide, insets: attributes.margin, axis: .horizontal, priority: .required - 1)
                contentView.anchors.centerX.align()
                // - height
                contentView.anchors.height.lessThanOrEqual(attributes.maxHeight)
                contentView.anchors.lessThanOrEqual(to: layoutMarginsGuide, insets: attributes.margin, axis: .vertical, priority: .required - 1)
                contentView.anchors.centerY.align()

                // ImageView
                if let imageView = imageView {
                    imageView.anchors.pin(axis: .horizontal)
                    if let image = imageView.image {
                        imageView.anchors.size.aspectRatio(image.size)
                    } else if let imageAspectRatio = imageAspectRatio {
                        imageView.anchors.size.aspectRatio(imageAspectRatio)
                    }
                }

                // TextView
                if let textView = textView, let textContainer = textContainer {
                    textContainer.layoutMargins = .init(top: 16, left: 16, bottom: 0, right: 16)
                    textView.textAlignment = .center
                    textView.anchors.pin(to: textContainer.layoutMarginsGuide)
                }

                // ButtonView
                if let buttonContainer = buttonContainer {
                    buttonContainer.stack.layoutMargins = .init(top: 16, left: 16, bottom: 16, right: 16)
                }

                // CloseButton
                if let closeButton = closeButton {
                    closeButton.anchors.size.equal(.init(width: 52, height: 52))
                    closeButton.anchors.top.pin()
                    closeButton.anchors.trailing.pin()
                }

                // OuterButtons
                for button in outerButtons {
                    button.alignOuter(to: contentView)
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

            anchors.pin()

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
                withDuration: 0.1,
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
                withDuration: 0.1,
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
                    self?.handle(event: .action(it.action, .button, it.text))
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

        lazy var outerButtons: [PositionalButtonView] = {
            context.message.outerButtons.map { it in
                let button = PositionalButtonView(button: it.button, alignment: it.alignment)
                button.onClick { [weak self] in
                    self?.handle(event: .action(it.button.action, .button, it.button.text))
                }
                return button
            }
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
