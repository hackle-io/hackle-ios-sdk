//
//  RemoteConfigParameterTargetRuleDeterminer.swift
//  Hackle
//
//  Created by yong on 2022/11/24.
//

import Foundation


class RemoteConfigParameterTargetRuleDeterminer {

    private let matcher: RemoteConfigParameterTargetRuleMatcher

    init(matcher: RemoteConfigParameterTargetRuleMatcher) {
        self.matcher = matcher
    }

    func determine(request: RemoteConfigLocalEvaluateRequest, context: EvaluatorContext) throws -> RemoteConfigParameter.TargetRule? {
        try request.parameter.targetRules.first { it in
            try matcher.matches(request: request, context: context, rule: it)
        }
    }
}


class RemoteConfigParameterTargetRuleMatcher {

    private let targetMatcher: TargetMatcher
    private let bucketer: Bucketer

    init(targetMatcher: TargetMatcher, bucketer: Bucketer) {
        self.targetMatcher = targetMatcher
        self.bucketer = bucketer
    }

    func matches(request: RemoteConfigLocalEvaluateRequest, context: EvaluatorContext, rule: RemoteConfigParameter.TargetRule) throws -> Bool {
        guard try targetMatcher.matches(request: request, context: context, target: rule.target) else {
            return false
        }

        guard let identifier = request.user.identifiers[request.parameter.identifierType] else {
            return false
        }

        guard let bucket = request.workspace.getBucketOrNil(bucketId: rule.bucketId) else {
            throw HackleError.error("Bucket[\(rule.bucketId)]")
        }

        return bucketer.bucketing(bucket: bucket, identifier: identifier) != nil
    }
}
