//
//  MockUserEventFactory.swift
//  HackleTests
//
//  Created by yong on 2023/04/19.
//

import Foundation
@testable import Hackle


class MockUserEventFactory: UserEventFactory {

    var events: [UserEvent] = []

    func create(request: EvaluatorRequest, evaluation: EvaluatorEvaluation) -> [UserEvent] {
        events
    }
}
