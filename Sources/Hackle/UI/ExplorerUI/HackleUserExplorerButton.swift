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
        let translation = sender.translation(in: self)

        let barHeight = HackleUserExplorerButton.barHeight()
        let bottomOffset = HackleUserExplorerButton.offset()

        let rect = UIScreen.main.bounds
        let width = rect.size.width
        let height = rect.size.height

        var newY = min(self.center.y + translation.y, height - bottomOffset)
        newY = max(barHeight + (self.bounds.height / 2), newY)

        var newX = min(self.center.x + translation.x, width)
        newX = max(self.bounds.width / 2, newX)

        self.center = CGPoint(x: newX, y: newY)
        sender.setTranslation(CGPoint(x: 0, y: 0), in: self)
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
