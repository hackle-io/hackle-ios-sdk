//
//  InAppMessageResolverStub.swift
//  HackleTests
//
//  Created by yong on 2023/06/26.
//

import Foundation
@testable import Hackle

class InAppMessageResolverStub: InAppMessageResolver {

    var message: InAppMessage.Message

    init(message: InAppMessage.Message = InAppMessage.message()) {
        self.message = message
    }

    func resolve(request: InAppMessageRequest, context: EvaluatorContext) throws -> InAppMessage.Message {
        message
    }
}