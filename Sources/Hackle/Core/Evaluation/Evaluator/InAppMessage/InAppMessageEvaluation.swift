//
//  InAppMessageEvaluation.swift
//  Hackle
//
//  Created by yong on 2023/06/01.
//

import Foundation


class InAppMessageEvaluation: EvaluatorEvaluation {
    let reason: String
    let targetEvaluations: [EvaluatorEvaluation]
    let inAppMessage: InAppMessage
    let message: InAppMessage.Message?
    let properties: [String: Any]

    init(
        reason: String,
        targetEvaluations: [EvaluatorEvaluation],
        inAppMessage: InAppMessage,
        message: InAppMessage.Message?,
        properties: [String: Any]
    ) {
        self.reason = reason
        self.targetEvaluations = targetEvaluations
        self.inAppMessage = inAppMessage
        self.message = message
        self.properties = properties
    }

    static func of(
        request: InAppMessageRequest,
        context: EvaluatorContext,
        reason: String,
        message: InAppMessage.Message? = nil
    ) -> InAppMessageEvaluation {
        InAppMessageEvaluation(
            reason: reason,
            targetEvaluations: context.targetEvaluations,
            inAppMessage: request.inAppMessage,
            message: message,
            properties: context.properties
        )
    }
}
