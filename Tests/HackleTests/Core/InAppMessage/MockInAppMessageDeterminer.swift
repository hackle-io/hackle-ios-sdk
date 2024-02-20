//
//  MockInAppMessageDeterminer.swift
//  HackleTests
//
//  Created by yong on 2023/06/27.
//

import Foundation
import Mockery
@testable import Hackle


class MockInAppMessageDeterminer: Mock, InAppMessageDeterminer {

    lazy var determineOrNullMock = MockFunction(self, determineOrNull)

    func determineOrNull(event: UserEvent) throws -> InAppMessagePresentationContext? {
        call(determineOrNullMock, args: event)
    }
}
