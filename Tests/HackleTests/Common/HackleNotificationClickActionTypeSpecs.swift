//
//  HackleNotificationClickActionTypeSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 4/18/25.
//

import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class HackleNotificationClickActionTypeSpecs: QuickSpec {
    override func spec() {
        it("from valid string") {
            expect(HackleNotificationClickActionType(rawValue: "DEEP_LINK")).to(equal(HackleNotificationClickActionType.deepLink))
            expect(HackleNotificationClickActionType(rawValue: "APP_OPEN")).to(equal(HackleNotificationClickActionType.appOpen))
        }
        
        it("frmo invalid string") {
            expect(HackleNotificationClickActionType(rawValue: "")).to(beNil())
            expect(HackleNotificationClickActionType(rawValue: "INVALID")).to(beNil())
        }
    }
}
