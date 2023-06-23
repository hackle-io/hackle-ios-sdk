//
//  UIKitExt.swift
//  Hackle
//
//  Created by yong on 2023/06/12.
//

import Foundation
import UIKit

extension UIColor {

    convenience init?(hex: String, alpha: CGFloat = 1.0) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        let scanner = Scanner(string: hexString)

        if hexString.hasPrefix("#") {
            scanner.scanLocation = 1
        }

        var color: UInt32 = 0
        if scanner.scanHexInt32(&color) {
            let mask = 0x000000FF
            let red = CGFloat(Int(color >> 16) & mask) / 255.0
            let green = CGFloat(Int(color >> 8) & mask) / 255.0
            let blue = CGFloat(Int(color) & mask) / 255.0

            self.init(red: red, green: green, blue: blue, alpha: alpha)
            return
        }
        return nil
    }
}

extension UIButton {

    func onClick(_ action: @escaping () -> ()) {
        @objc final class Listener: NSObject {
            let action: () -> ()

            init(_ action: @escaping () -> ()) {
                self.action = action
            }

            @objc func onClick() {
                action()
            }
        }

        let listener = Listener(action)
        self.addTarget(listener, action: #selector(Listener.onClick), for: .touchUpInside)
        objc_setAssociatedObject(self, UUID().uuidString, listener, .OBJC_ASSOCIATION_RETAIN)
    }
}
