//
//  MockInAppMessagePresenter.swift
//  HackleTests
//
//  Created by yong on 2023/06/27.
//

import Foundation
import Mockery
@testable import Hackle


class MockInAppMessagePresenter: Mock, InAppMessagePresenter {

    lazy var presentMock = MockFunction(self, present)

    func present(context: InAppMessageContext) {
        call(presentMock, args: context)
    }
}