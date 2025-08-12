//
//  MockPIIEventManager.swift
//  Hackle
//
//  Created by sungwoo.yeo on 3/31/25.
//

import Foundation
import Mockery
@testable import Hackle

class MockPIIEventManager: Mock, PIIEventManager {
    lazy var setPhoneNumberRef = MockFunction(self, setPhoneNumber)
    func setPhoneNumber(phoneNumber: PhoneNumber) -> Event {
        call(setPhoneNumberRef, args: (phoneNumber))
    }
    
    lazy var unsetPhoneNumberRef = MockFunction(self, unsetPhoneNumber)
    func unsetPhoneNumber() -> Event {
        call(unsetPhoneNumberRef, args: ())
    }
}
