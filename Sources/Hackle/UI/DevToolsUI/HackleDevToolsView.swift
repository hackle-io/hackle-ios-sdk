//
//  HackleDevToolsView.swift
//  Hackle
//
//  Created by yong on 2023/03/24.
//

import Foundation
import UIKit


@MainActor
class HackleDevToolsView {
    private var button: HackleDevToolsButton? = nil
    private var urlView: UIView? = nil

    func attach() {
        guard let window = UIUtils.keyWindow else {
            return
        }

        if window.subviews.contains(where: { view in
            view is HackleDevToolsButton
        }) {
            return
        }

        if self.button == nil {
            self.button = self.createButton(in: window)
        }
        let button = self.button!
        window.addSubview(button)
    }

    func detach() {
        guard let _ = UIUtils.keyWindow else {
            return
        }

        self.hideUrl()
        self.button?.removeFromSuperview()
        self.button = nil
    }

    private func createButton(in window: UIWindow) -> HackleDevToolsButton {
        let width = window.bounds.width
        let height = window.bounds.height
        let offset = offset()
        let button = HackleDevToolsButton(frame: CGRect(
            x: width - 50,
            y: height - 50 - offset,
            width: 35,
            height: 35
        ))
        button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClick)))
        button.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onTouch)))
        return button
    }

    @objc func onTouch(sender: UIPanGestureRecognizer) {
        guard let button = self.button,
              let superview = button.superview else {
            Log.debug("FloatingButton: button or superview is nil during drag")
            return
        }
        let translation = sender.translation(in: button)

        let barHeight = barHeight()
        let bottomOffset = offset()

        let width = superview.bounds.width
        let height = superview.bounds.height

        var newY = min(button.center.y + translation.y, height - bottomOffset)
        newY = max(barHeight + (button.bounds.height / 2), newY)

        var newX = min(button.center.x + translation.x, width)
        newX = max(button.bounds.width / 2, newX)

        button.center = CGPoint(x: newX, y: newY)
        sender.setTranslation(CGPoint(x: 0, y: 0), in: button)
        layoutUrl()
    }

    @objc func onClick() {
        guard self.button != nil else {
            return
        }
        if urlView == nil {
            showUrl()
        } else {
            hideUrl()
        }
    }

    private func showUrl() {
        guard let button = self.button,
              let superview = button.superview else {
            return
        }
        let url = DevToolsRegistry.url()
        let label = UILabel()
        label.text = url ?? "DevTools is not running"
        label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .white
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping

        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        container.layer.cornerRadius = 8
        container.addSubview(label)
        if url != nil {
            let copyButton = UIButton(type: .system)
            copyButton.tintColor = .white
            copyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
            copyButton.addTarget(self, action: #selector(onCopyClick), for: .touchUpInside)
            container.addSubview(copyButton)
        }
        superview.addSubview(container)
        urlView = container
        layoutUrl()
    }

    @objc func onCopyClick(sender: UIButton) {
        guard let url = DevToolsRegistry.url() else {
            return
        }
        UIPasteboard.general.string = url
        sender.setImage(UIImage(systemName: "checkmark"), for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak sender] in
            sender?.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        }
    }

    private func hideUrl() {
        urlView?.removeFromSuperview()
        urlView = nil
    }

    private func layoutUrl() {
        guard let button = self.button,
              let superview = button.superview,
              let container = urlView,
              let label = container.subviews.first(where: { $0 is UILabel }) else {
            return
        }
        let copyButton = container.subviews.first(where: { $0 is UIButton })
        let padding: CGFloat = 10
        let margin: CGFloat = 16
        let spacing: CGFloat = 8
        let copySize: CGFloat = copyButton == nil ? 0 : 24
        let copySpacing: CGFloat = copyButton == nil ? 0 : 8
        let maxLabelWidth = superview.bounds.width - margin * 2 - padding * 2 - copySize - copySpacing
        let labelSize = label.sizeThatFits(CGSize(width: maxLabelWidth, height: .greatestFiniteMagnitude))
        let labelWidth = min(labelSize.width, maxLabelWidth)
        let width = labelWidth + copySpacing + copySize + padding * 2
        let height = max(labelSize.height, copySize) + padding * 2

        var x = button.center.x - width / 2
        x = max(margin, min(x, superview.bounds.width - margin - width))
        let y = button.center.y > superview.bounds.height / 2
            ? button.frame.minY - spacing - height
            : button.frame.maxY + spacing

        container.frame = CGRect(x: x, y: y, width: width, height: height)
        label.frame = CGRect(x: padding, y: (height - labelSize.height) / 2, width: labelWidth, height: labelSize.height)
        copyButton?.frame = CGRect(x: width - padding - copySize, y: (height - copySize) / 2, width: copySize, height: copySize)
    }

    private func barHeight() -> CGFloat {
        guard let size = UIUtils.keyWindow?.windowScene?.statusBarManager?.statusBarFrame.size else {
            return 0.0
        }
        return min(size.width, size.height)
    }

    private func offset() -> CGFloat {
        barHeight() > 24.0 ? 30.0 : 0.0
    }
}
