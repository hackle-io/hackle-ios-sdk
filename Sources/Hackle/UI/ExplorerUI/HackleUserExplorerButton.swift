//
//  HackleUserExplorerButton.swift
//  Hackle
//
//  Created by yong on 2023/03/24.
//

import UIKit

class HackleUserExplorerButton: UIView {
    /// delegate for tap action
    var tapDelegate: (() -> Void)?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    private func commonInit() {
        loadViewFromNib()
        setupGestures()
    }

    func loadViewFromNib() {
        guard let view = HackleInternalResources.bundle.loadNibNamed("HackleUserExplorerButton", owner: self)?.first as? UIView else {
            return
        }
        
        view.frame = bounds
        addSubview(view)
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onTouch))
        
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(panGesture)
    }
    
    @objc private func handleTap() {
        tapDelegate?()
    }
    
    @objc private func onTouch(sender: UIPanGestureRecognizer) {
        guard let superview = self.superview else { return }
        let translation = sender.translation(in: superview)
        let halfWidth = self.bounds.width / 2
        let halfHeight = self.bounds.height / 2
        let topPadding = HackleUserExplorerButton.barHeight()
        let offset = HackleUserExplorerButton.offset()

        let minX = offset + halfWidth
        let maxX = superview.bounds.width - offset - halfWidth
        let minY = topPadding + halfHeight
        let maxY = superview.bounds.height - offset - halfHeight

        var newCenter = self.center
        newCenter.x += translation.x
        newCenter.y += translation.y

        newCenter.x = max(minX, min(newCenter.x, maxX))
        newCenter.y = max(minY, min(newCenter.y, maxY))

        self.center = newCenter
        sender.setTranslation(.zero, in: superview)
    }
}

extension HackleUserExplorerButton {
    static func barHeight() -> CGFloat {
        if #available(iOS 13.0, *) {
            guard let size = UIUtils.keyWindow?.windowScene?.statusBarManager?.statusBarFrame.size else {
                return 0.0
            }
            return min(size.width, size.height)
        } else {
            guard let application = UIUtils.application else {
                return 0.0
            }
            let size = application.statusBarFrame.size
            return min(size.width, size.height)
        }
    }

    static func offset() -> CGFloat {
        barHeight() > 24.0 ? 30.0 : 0.0
    }
}
