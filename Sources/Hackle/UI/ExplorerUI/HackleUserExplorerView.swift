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
    private var buttonWindow: UIWindow? = nil
    
    func attach() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            if #available(iOS 13.0, *) {
                self.createButtonWindow()
            } else {
                self.addButtonToCurrentView()
            }
        }
    }

    func detach() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            if #available(iOS 13.0, *) {
                self.removeButtonWindow()
            } else {
                self.removeButtonFromCurrentView()
            }
        }
    }
    
    @available(iOS 13.0, *)
    private func createButtonWindow() {
        self.button = self.createButton()
        buttonWindow = UIWindow.show(floatingView: self.button!)
    }
    
    private func addButtonToCurrentView() {
        guard let window = UIUtils.keyWindow else {
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
    
    @available(iOS 13.0, *)
    private func removeButtonWindow() {
        if let buttonWindow = self.buttonWindow {
            buttonWindow.isHidden = true
            self.buttonWindow = nil
        }
    }
    
    private func removeButtonFromCurrentView() {
        if self.button != nil {
            self.button?.removeFromSuperview()
            self.button = nil
        }
    }

    private func createButton() -> HackleUserExplorerButton {
        let rect = if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
            UIUtils.keyWindow?.bounds ?? UIScreen.main.bounds
        } else {
            UIScreen.main.bounds
        }

        let width = rect.size.width
        let height = rect.size.height
        let offset = HackleUserExplorerButton.offset()
        
        let button = HackleUserExplorerButton(frame: CGRect(
            x: width - 50,
            y: height - 50 - offset,
            width: 35,
            height: 35
        ))
        
        button.tapDelegate = { [weak self] in
            self?.onClick()
        }

        return button
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
            hackleUserExplorerViewController.modalPresentationStyle = .fullScreen
            topViewController.present(hackleUserExplorerViewController, animated: true)
        }
    }
}
