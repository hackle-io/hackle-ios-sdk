//
//  HackleUserExplorerView.swift
//  Hackle
//
//  Created by yong on 2023/03/24.
//

import Foundation
import UIKit


class HackleUserExplorerView {

    private var button: HackleUserExplorerButton? = nil

    func attach() {
        DispatchQueue.main.async {
            let rect = UIScreen.main.bounds
            let width = rect.size.width
            let height = rect.size.height
            let offset = self.offset()

            let button = HackleUserExplorerButton(frame: CGRect(
                x: width - 50,
                y: height - 50 - offset,
                width: 35,
                height: 35
            ))
            self.button = button

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
                self.getKeyWindow()?.addSubview(button)
            }

            button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onClick)))
            button.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.onTouch)))
        }
    }

    private func getKeyWindow() -> UIWindow? {
        if #available(iOS 13, *) {
            return UIApplication.shared.connectedScenes
                .filter {
                    $0.activationState == .foregroundActive
                }
                .compactMap {
                    $0 as? UIWindowScene
                }
                .first?.windows
                .filter {
                    $0.isKeyWindow
                }
                .first
        } else {
            return UIApplication.shared.windows.first { window in
                window.isKeyWindow
            }
        }
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
        DispatchQueue.main.async {
            if self.button != nil {
                let rootViewController = self.getKeyWindow()?.rootViewController
                let hackleUserExplorerViewController = HackleUserExplorerViewController(nibName: "HackleUserExplorerViewController", bundle: HackleResources.bundle)
                hackleUserExplorerViewController.modalPresentationStyle = .fullScreen
                rootViewController?.present(hackleUserExplorerViewController, animated: true)
            }
        }
    }

    private func barHeight() -> CGFloat {
        if #available(iOS 13.0, *) {
            guard let size = getKeyWindow()?.windowScene?.statusBarManager?.statusBarFrame.size else {
                return 0.0
            }
            return min(size.width, size.height)
        } else {
            let size = UIApplication.shared.statusBarFrame.size
            return min(size.width, size.height)
        }
    }

    private func offset() -> CGFloat {
        barHeight() > 24.0 ? 30.0 : 0.0
    }
}
