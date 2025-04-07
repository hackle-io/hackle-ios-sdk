//
//  DefaultPIIEventManagerSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 3/31/25.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultPIIEventManagerSpecs: QuickSpec {
    override func spec() {
        var userManager: MockUserManager!
        var core: MockHackleCore!
        var sut: DefaultPIIEventManager!
        
        beforeEach {
            userManager = MockUserManager()
            core = MockHackleCore()
            sut = DefaultPIIEventManager(userManager: userManager, core: core)
        }
        
        it("set phone number") {
            // given
            every(userManager.toHackleUserMock).returns(HackleUser.builder().build())
            let user = User.builder().deviceId("device_id").build()
            let phoneNumber = "+821012345678"
            
            // when
            sut.setPhoneNumber(phoneNumber: PhoneNumber(value: phoneNumber), timestamp: Date(timeIntervalSince1970: 42))
            
            // then
            verify(exactly: 1) {
                core.trackMock
            }
            
            let event = core.trackMock.firstInvokation().arguments.0
            expect(event.key).to(equal("$secured_properties"))
            
            let properties = event.properties?["$set"] as? [String: Any]
            expect(properties?.count).to(equal(1))
            expect(properties?["$phone_number"] as? String).to(equal(phoneNumber))
        }
        
        it("unset phone number") {
            // given
            every(userManager.toHackleUserMock).returns(HackleUser.builder().build())
            let user = User.builder().deviceId("device_id").build()
            
            // when
            sut.unsetPhoneNumber(timestamp: Date(timeIntervalSince1970: 42))
            
            // then
            verify(exactly: 1) {
                core.trackMock
            }
        }
    }
}
