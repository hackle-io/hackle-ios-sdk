//
//  HackleInAppMessage.swift
//  Hackle
//
//  Created by hackle on 8/28/24.
//

import Foundation

@objc public protocol HackleInAppMessage {
    var key: Int64 { get }
}
