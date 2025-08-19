//
//  HackleAppInvocator.swift
//  Hackle
//
//  Created by sungwoo.yeo on 8/19/25.
//

import Foundation

@objc public final class HackleAppInvocator: NSObject {
    @objc public static func hackleInvocator() throws -> HackleInvocator {
        guard let hackleApp = Hackle.app() else {
            throw HackleError.error("HackleApp is not initialized. Make sure to call Hackle.initialize() first")
        }
        
        return hackleApp.invocator()
    }
}
