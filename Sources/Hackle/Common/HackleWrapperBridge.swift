//
//  HackleWrapperBridge.swift
//  Hackle
//
//  Created by sungwoo.yeo on 5/20/25.
//

import Foundation

@objc public protocol HackleWrapperBridge {
    func invoke(_ prompt: String) -> String
}
