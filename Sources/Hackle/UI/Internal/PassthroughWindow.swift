//
//  PassthroughWindow.swift
//  Hackle
//
//  Created by sungwoo.yeo on 7/15/25.
//

import UIKit

class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if hitView === self.rootViewController?.view {
            return nil
        }
        return hitView
    }
}
