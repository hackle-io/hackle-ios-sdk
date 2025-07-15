//
//  HackleUserExplorerView.swift
//  Hackle
//
//  Created by yong on 2023/03/24.
//

import Foundation
import UIKit


class HackleUserExplorerView {
    private var buttonWindow: UIWindow? = nil
    
    func attach() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, buttonWindow == nil else {
                return
            }
            
            let button = self.createButton()
            buttonWindow = createWindow(floatingButtonView: button)
            buttonWindow?.isHidden = false
        }
    }

    func detach() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            
            if let buttonWindow = self.buttonWindow {
                buttonWindow.isHidden = true
                
                if #available(iOS 13.0, *) {
                    self.buttonWindow?.windowScene = nil
                }
                
                self.buttonWindow = nil
            }
        }
    }

    private func createButton() -> HackleUserExplorerButton {
        let rect = UIUtils.keyWindow?.bounds ?? UIScreen.main.bounds

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
                  let rootViewController = self.buttonWindow?.rootViewController
            else {
                return
            }

            let hackleUserExplorerViewController = HackleUserExplorerViewController(nibName: "HackleUserExplorerViewController", bundle: HackleInternalResources.bundle)
            hackleUserExplorerViewController.modalPresentationStyle = .fullScreen
            rootViewController.present(hackleUserExplorerViewController, animated: true)
        }
    }
}
