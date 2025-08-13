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
        var sut: DefaultPIIEventManager!
        
        beforeEach {
            sut = DefaultPIIEventManager()
        }
        
        it("set phone number") {
            // given
            let phoneNumber = "+821012345678"
            
            // when
            let event = sut.setPhoneNumber(phoneNumber: PhoneNumber(value: phoneNumber))
            
            // then
            expect(event.key).to(equal("$secured_properties"))
            
            let properties = event.properties?["$set"] as? [String: Any]
            expect(properties?.count).to(equal(1))
            expect(properties?["$phone_number"] as? String).to(equal(phoneNumber))
        }
        
        it("unset phone number") {
            // when
            let event = sut.unsetPhoneNumber()
            
            // then
            expect(event.key).to(equal("$secured_properties"))
            
            let properties = event.properties?["$unset"] as? [String: Any]
            expect(properties?.count).to(equal(1))
            expect(properties?["$phone_number"] as? String).to(equal("-"))
        }
    }
}
