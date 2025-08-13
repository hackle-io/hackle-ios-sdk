//
//  HackleAppBridge.swift
//  Hackle
//
//  Created by sungwoo.yeo on 8/12/25.
//

import Foundation

@objc public protocol HackleAppBridge {
    @objc func isInvocableString(string: String) -> Bool
    @objc func invoke(string: String) -> String
    @objc func invoke(string: String, completionHandler: (String?) -> Void)
}
