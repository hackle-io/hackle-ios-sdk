//
//  HackleAppBridge.swift
//  Hackle
//
//  Created by sungwoo.yeo on 8/12/25.
//

import Foundation

@objc public protocol HackleAppBridge {
    func isInvocableString(string: String) -> Bool
    func invoke(string: String) -> String
    func invoke(string: String, completionHandler: (String?) -> Void)
}
