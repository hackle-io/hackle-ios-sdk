import Foundation
import UIKit

extension HackleInAppMessageUI {

    class ImageContainerView: UIView {

        private let attributes: Attributes

        private let items: [ImageItem]
        private let handleEvent: (InAppMessage.Event) -> ()

        init(items: [ImageItem], attributes: Attributes, handleEvent: @escaping (InAppMessage.Event) -> ()) {
            self.attributes = attributes
            self.items = items
            self.handleEvent = handleEvent
            super.init(frame: .zero)

            if let singleImageView = singleImageView {
                addSubview(singleImageView)
                singleImageView.anchors.pin()
            }

            if let scrollImageView = scrollImageView {
                addSubview(scrollImageView)
                scrollImageView.anchors.pin()
            }
        }

        public required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        struct Attributes {
            var autoScrollInterval: TimeInterval? = nil
        }

        lazy var tapImageViewGesture = UITapGestureRecognizer(target: self, action: #selector(tapImageView))

        @objc func tapImageView(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended,
                  let item = items.first,
                  let action = item.image.action
            else {
                return
            }

            handleEvent(.imageAction(action: action, image: item.image, order: nil))
        }

        // MARK: - View

        private lazy var singleImageView: UIImageView? = {
            guard items.count == 1 else {
                return nil
            }
            let view = UIImageView()
            view.contentMode = .scaleToFill
            view.addGestureRecognizer(tapImageViewGesture)
            view.isUserInteractionEnabled = true
            view.loadImage(url: items.first!.image.imagePath)
            return view
        }()

        private lazy var scrollImageView: ScrollImageView? = {
            guard items.count > 1 else {
                return nil
            }

            let attributes = ScrollImageView.Attributes(autoScrollInterval: attributes.autoScrollInterval)
            let view = ScrollImageView(items: items, attributes: attributes) { [weak self] event in
                self?.handleEvent(event)
            }
            return view
        }()
    }

    class ImageItem {
        let image: InAppMessage.Message.Image
        let order: Int // starts from 1

        init(image: InAppMessage.Message.Image, order: Int) {
            self.image = image
            self.order = order
        }
    }
}
