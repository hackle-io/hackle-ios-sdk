import Foundation
import UIKit

extension HackleInAppMessageUI {

    class ScrollImageView: UIView, InAppMessageViewLifecycleListener, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

        private let context: ScrollContext
        private let handleEvent: (InAppMessage.Event) -> ()
        private var attributes: Attributes
        private var initialized: Bool = false
        private var timer: Foundation.Timer? = nil

        init(items: [ImageItem], attributes: Attributes, handleEvent: @escaping (InAppMessage.Event) -> ()) {
            self.context = ScrollContext(items: items)
            self.handleEvent = handleEvent
            self.attributes = attributes
            super.init(frame: .zero)

            // CollectionView
            collectionView.register(Cell.self, forCellWithReuseIdentifier: Cell.identifier)
            collectionView.delegate = self
            collectionView.dataSource = self
            addSubview(collectionView)
            collectionView.anchors.pin()

            // PageView
            addSubview(pageView)
            pageView.anchors.trailing.pin(inset: 16)
            pageView.anchors.top.pin(inset: 16)
            pageView.anchors.size.equal(.init(width: 46, height: 20))

            updatePage(extendedIndex: 1)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        deinit {
            stopAutoScroll()
        }

        struct Attributes {
            var autoScrollInterval: TimeInterval? = nil
        }

        private var currentIndex: Int {
            Int(collectionView.contentOffset.x / collectionView.frame.width)
        }

        // MARK: - Page

        private func updatePage(extendedIndex: Int) {
            let item = context.item(extendedIndex: extendedIndex)
            pageView.text = "\(item.order) / \(context.originalCount)"
        }

        // MARK: - Impression

        private var impressions: [Int: Bool] = [:]

        private func impressionIfNeeded(extendedIndex: Int) {
            let item = context.item(extendedIndex: extendedIndex)
            let isFirstImpression = impressions[item.order] == nil
            if isFirstImpression {
                impressions[item.order] = true
                handleEvent(.imageImpression(image: item.image, order: item.order))
            }
        }

        // MARK: - AutoScroll

        private func startAutoScroll() {
            stopAutoScroll()
            if let interval = attributes.autoScrollInterval {
                timer = .scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                    self?.scroll()
                }
            }
        }

        private func stopAutoScroll() {
            timer?.invalidate()
            timer = nil
        }

        @objc func scroll() {
            let nextIndex = currentIndex + 1
            if nextIndex < context.extendedCount {
                collectionView.scrollToItem(at: .init(item: nextIndex, section: 0), at: .centeredHorizontally, animated: true)
            }

            if let adjustedIndex = context.adjustIndex(extendedIndex: nextIndex) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.collectionView.scrollToItem(at: .init(item: adjustedIndex, section: 0), at: .centeredHorizontally, animated: false)
                }
            }

            updatePage(extendedIndex: nextIndex)
            impressionIfNeeded(extendedIndex: nextIndex)
        }

        // MARK: - View Lifecycle

        func inAppMessageDidPresent() {
            impressionIfNeeded(extendedIndex: currentIndex)
            startAutoScroll()
        }

        func inAppMessageWillDismiss() {
            stopAutoScroll()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            if !initialized && collectionView.bounds.size != .zero {
                initialized = true
                collectionView.scrollToItem(at: .init(item: 1, section: 0), at: .centeredHorizontally, animated: false)
            }
        }

        // MARK: - UICollectionViewDelegate

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let item = context.item(extendedIndex: indexPath.item)
            guard let action = item.image.action else {
                return
            }
            handleEvent(.imageAction(action: action, image: item.image, order: item.order))
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            stopAutoScroll()
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            if let adjustedIndex = context.adjustIndex(extendedIndex: currentIndex) {
                collectionView.scrollToItem(at: .init(item: adjustedIndex, section: 0), at: .centeredHorizontally, animated: false)
            }
            updatePage(extendedIndex: currentIndex)
            impressionIfNeeded(extendedIndex: currentIndex)
            startAutoScroll()
        }

        // MARK: - UICollectionViewDataSource

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return context.extendedCount
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.identifier, for: indexPath) as! Cell
            let item = context.item(extendedIndex: indexPath.item)
            cell.configure(image: item.image)
            return cell
        }

        // MARK: - UICollectionViewDelegateFlowLayout

        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return collectionView.frame.size
        }

        // MARK: - Views

        private lazy var collectionView: UICollectionView = {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.minimumLineSpacing = 0
            layout.estimatedItemSize = .zero

            let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
            view.isPagingEnabled = true
            view.showsHorizontalScrollIndicator = false
            return view
        }()


        private lazy var pageView: UILabel = {
            let view = UILabel()
            view.backgroundColor = UIColor(hex: "#1c1c1c", alpha: 0.5)
            view.textColor = .white
            view.font = .systemFont(ofSize: 10)
            view.textAlignment = .center
            view.layer.cornerRadius = 10
            view.clipsToBounds = true
            return view
        }()

        private class Cell: UICollectionViewCell {
            static let identifier = "HackleInAppMessageUI.ScrollImageView.Cell"

            override init(frame: CGRect) {
                super.init(frame: .zero)
                contentView.addSubview(imageView)
                contentView.anchors.pin()
                layout()
            }

            private func layout() {
                imageView.anchors.pin()
            }

            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }

            func configure(image: InAppMessage.Message.Image) {
                imageView.loadImage(url: image.imagePath) {
                    self.layout()
                }
            }

            private lazy var imageView: UIImageView = {
                let view = UIImageView()
                view.contentMode = .scaleAspectFill
                return view
            }()
        }
    }

    class ScrollContext {
        private let items: [ImageItem]

        init(items: [ImageItem]) {
            self.items = items
        }

        var originalCount: Int {
            return items.count
        }

        var extendedCount: Int {
            return originalCount + 2
        }

        func originalIndex(extendedIndex: Int) -> Int {
            return (extendedIndex - 1 + originalCount) % originalCount
        }

        func item(extendedIndex: Int) -> ImageItem {
            return items[originalIndex(extendedIndex: extendedIndex)]
        }

        func adjustIndex(extendedIndex: Int) -> Int? {
            if extendedIndex == 0 {
                return extendedCount - 2
            } else if extendedIndex == extendedCount - 1 {
                return 1
            } else {
                return nil
            }
        }
    }
}
