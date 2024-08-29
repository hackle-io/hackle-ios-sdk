//
//  HackleInAppMessageView.swift
//  Hackle
//
//  Created by hackle on 8/28/24.
//

import Foundation

@objc public protocol HackleInAppMessageView {
    var inAppMessage: HackleInAppMessage { get }
    func close()
}
