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
    lazy var toSetPhoneNumberMock = MockFunction(self, setPhoneNumber)
    func setPhoneNumber(phoneNumber: PhoneNumber, timestamp: Date) {
        call(toSetPhoneNumberMock, args: (phoneNumber, timestamp))
    }
    
    lazy var toUnsetPhoneNumberMock = MockFunction(self, unsetPhoneNumber)
    func unsetPhoneNumber(timestamp: Date) {
        call(toUnsetPhoneNumberMock, args: (timestamp))
    }
}
