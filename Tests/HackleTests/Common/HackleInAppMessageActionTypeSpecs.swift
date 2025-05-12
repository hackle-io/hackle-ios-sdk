//
//  HackleInAppMessageActionTypeSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 5/7/25.
//

import Quick
import Nimble
@testable import Hackle

class HackleInAppMessageActionTypeSpecs: QuickSpec {
    override func spec() {
        describe("HackleInAppMessageActionType") {
            it("rawValue로 초기화가 정상 동작한다") {
                expect(HackleInAppMessageActionType(rawValue: "CLOSE")) == .close
                expect(HackleInAppMessageActionType(rawValue: "LINK")) == .link
                expect(HackleInAppMessageActionType(rawValue: "INVALID")).to(beNil())
            }
            
            it("enum에서 rawValue 변환이 정상 동작한다") {
                expect(HackleInAppMessageActionType.close.rawValue) == "CLOSE"
                expect(HackleInAppMessageActionType.link.rawValue) == "LINK"
            }
        }
    }
}
