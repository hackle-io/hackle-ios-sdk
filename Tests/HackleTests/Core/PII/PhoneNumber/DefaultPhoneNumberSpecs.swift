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
        it("phone number") {
            let phoneNumber = "01012345678"
            let result = PhoneNumber.create(phoneNumber: phoneNumber)
            expect(result.value) == phoneNumber
        }
    }
}
