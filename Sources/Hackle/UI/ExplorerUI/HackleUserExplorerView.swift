//
//  HackleUserExplorerView.swift
//  Hackle
//
//  Created by yong on 2023/03/24.
//

import Foundation
import UIKit


class HackleUserExplorerView {
    private let hackleUserExplorer: HackleUserExplorer
    private var button: HackleUserExplorerButton? = nil
    
    init(hackleUserExplorer: HackleUserExplorer) {
        self.hackleUserExplorer = hackleUserExplorer
    }

    func attach() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let window = UIUtils.keyWindow else {
                return
            }

            if window.subviews.contains(where: { view in
                view is HackleUserExplorerButton
            }) {
                return
            }

            if self.button == nil {
                self.button = self.createButton()
            }
            let button = self.button!

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                window.addSubview(button)
            }
        }
    }

    func detach() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let _ = UIUtils.keyWindow else {
                return
            }

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                if self.button != nil {
                    self.button?.removeFromSuperview()
                    self.button = nil
                }
            }
        }
    }

    private func createButton() -> HackleUserExplorerButton {
        let rect = UIScreen.main.bounds
        let width = rect.size.width
        let height = rect.size.height
        let offset = offset()
        let button = HackleUserExplorerButton(frame: CGRect(
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
        let translation = sender.translation(in: button)

        let barHeight = barHeight()
        let bottomOffset = offset()

        let rect = UIScreen.main.bounds
        let width = rect.size.width
        let height = rect.size.height

        var newY = min(button!.center.y + translation.y, height - bottomOffset)
        newY = max(barHeight + (button!.bounds.height / 2), newY)

        var newX = min(button!.center.x + translation.x, width)
        newX = max(button!.bounds.width / 2, newX)

        button!.center = CGPoint(x: newX, y: newY)
        sender.setTranslation(CGPoint(x: 0, y: 0), in: button)
    }

    @objc func onClick() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  self.button != nil,
                  let topViewController = UIUtils.topViewController
            else {
                return
            }
            let hackleUserExplorerViewController = HackleUserExplorerViewController(nibName: "HackleUserExplorerViewController", bundle: HackleInternalResources.bundle)
            hackleUserExplorerViewController.setHackleUserExplorer(hackleUserExplorer)
            hackleUserExplorerViewController.modalPresentationStyle = .fullScreen
            topViewController.present(hackleUserExplorerViewController, animated: true)
        }
    }

    private func barHeight() -> CGFloat {
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

    private func offset() -> CGFloat {
        barHeight() > 24.0 ? 30.0 : 0.0
    }
}

protocol HackleUserExplorerContainer {
    func setHackleUserExplorer(_ hackleUserExplorer: HackleUserExplorer)
}
