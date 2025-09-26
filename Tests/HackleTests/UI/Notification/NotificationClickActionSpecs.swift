//
//  NotificationClickActionSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 4/18/25.
//

import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class NotificationClickActionSpecs: QuickSpec {
    override func spec() {
        it("from valid string") {
            expect(NotificationClickAction.from(rawValue: "DEEP_LINK")).to(equal(NotificationClickAction.deepLink))
            expect(NotificationClickAction.from(rawValue: "APP_OPEN")).to(equal(NotificationClickAction.appOpen))
        }
        
        it("frmo invalid string") {
            expect(NotificationClickAction.from(rawValue: nil)).to(equal(NotificationClickAction.appOpen))
            expect(NotificationClickAction.from(rawValue: "INVALID")).to(equal(NotificationClickAction.appOpen))
        }
    }
}
