//
//  InAppMessageEventTracker.swift
//  Hackle
//
//  Created by yong on 2023/06/20.
//

import Foundation

extension InAppMessage {
    enum Event {
        case impression
        case close
        case action(Action, ActionArea, String? = nil)
    }
}
