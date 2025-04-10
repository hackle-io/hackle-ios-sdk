//
//  DefaultPhoneNumberSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 3/31/25.
//

import Quick
import Nimble
@testable import Hackle


class DefaultPhoneNumberSpecs: QuickSpec {
    override func spec() {
        it("filtered phone number with +") {
            let phoneNumberCases = [
                "+821012345678",
                "+82-10-1234-5678",
                "+82 10 1234 5678",
                "+82 10 1234-5678",
                "+82(10)12345678",
                "+82(10)1234-5678",
                "+82(10)1234 5678",
                "+82-10-1234-5678aaa",
                "aaa+82 10 1234 5678",
            ]
            let expectResult = "+821012345678"
            
            for phoneNumber in phoneNumberCases {
                let result = PhoneNumber.create(phoneNumber: phoneNumber)
                expect(result.value) == expectResult
            }
        }
        
        it("filtered phone number") {
            let phoneNumberCases = [
                "01012345678",
                "01012345678",
                "010-1234-5678",
                "010 1234 5678",
                "010 1234-5678",
                "010(1234)5678",
                "010(1234)5678",
                "010(1234)5678aaa",
                "aaa010 1234 5678",
            ]
            let expectResult = "01012345678"
            
            for phoneNumber in phoneNumberCases {
                let result = PhoneNumber.create(phoneNumber: phoneNumber)
                expect(result.value) == expectResult
            }
        }
    }
}
