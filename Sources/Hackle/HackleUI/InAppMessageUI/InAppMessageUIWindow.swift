//
//  InAppMessageUIWindow.swift
//  Hackle
//
//  Created by yong on 2023/06/12.
//

import Foundation
import UIKit

extension HackleInAppMessageUI {
    class Window: UIWindow {
        var messageViewController: ViewController? {
            rootViewController as? ViewController
        }
    }
}
