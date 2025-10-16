//
//  MockUserEventBackoffController.swift
//  Hackle
//
//  Created by sungwoo.yeo on 7/11/25.
//

import MockingKit
@testable import Hackle

class MockUserEventBackoffController: Mock, UserEventBackoffController {
    
    lazy var checkResponseMock = MockFunction(self, checkResponse)
    
    func checkResponse(_ isSuccess: Bool) {
        call(checkResponseMock, args: (isSuccess))
    }
    
    lazy var isAllowNextFlushMock = MockFunction(self, isAllowNextFlush)
    
    func isAllowNextFlush() -> Bool {
        call(isAllowNextFlushMock, args: ())
    }
    
}
