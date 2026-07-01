//
//  SegmentConditionMatcher.swift
//  Hackle
//
//  Created by yong on 2023/04/17.
//

import Foundation

class SegmentConditionMatcher: ConditionMatcher {

    private let segmentMatcher: SegmentMatcher

    init(segmentMatcher: SegmentMatcher) {
        self.segmentMatcher = segmentMatcher
    }

    func matches(request: EvaluateRequest, context: EvaluatorContext, condition: Target.Condition) throws -> Bool {
        guard let request = request as? LocalEvaluateRequest else {
            return false
        }
        guard condition.key.type == .segment else {
            throw HackleError.error("Unsupported TargetKeyType [\(condition.key.type)]")
        }
        let isMatched = try condition.match.values.contains { it in
            try matches(request: request, context: context, value: it)
        }
        return condition.match.type.matches(isMatched)
    }

    private func matches(request: LocalEvaluateRequest, context: EvaluatorContext, value: HackleValue) throws -> Bool {
        guard let segmentKey = value.stringOrNil else {
            throw HackleError.error("SegmentKey[\(value)]")
        }
        guard let segment = request.workspace.getSegmentOrNil(segmentKey: segmentKey) else {
            throw HackleError.error("Segment[\(segmentKey)]")
        }
        return try segmentMatcher.matches(request: request, context: context, segment: segment)
    }
}

protocol SegmentMatcher {
    func matches(request: LocalEvaluateRequest, context: EvaluatorContext, segment: Segment) throws -> Bool
}

class DefaultSegmentMatcher: SegmentMatcher {

    private let userConditionMatcher: ConditionMatcher

    init(userConditionMatcher: ConditionMatcher) {
        self.userConditionMatcher = userConditionMatcher
    }

    func matches(request: LocalEvaluateRequest, context: EvaluatorContext, segment: Segment) throws -> Bool {
        try segment.targets.contains { it in
            try matches(request: request, context: context, target: it)
        }
    }

    private func matches(request: LocalEvaluateRequest, context: EvaluatorContext, target: Target) throws -> Bool {
        try target.conditions.allSatisfy { it in
            try userConditionMatcher.matches(request: request, context: context, condition: it)
        }
    }
}
