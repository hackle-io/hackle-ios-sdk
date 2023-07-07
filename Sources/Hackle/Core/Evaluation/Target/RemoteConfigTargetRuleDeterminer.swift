//
//  RemoteConfigTargetRuleDeterminer.swift
//  Hackle
//
//  Created by yong on 2022/11/24.
//

import Foundation


protocol RemoteConfigTargetRuleDeterminer {
    func determineTargetRuleOrNil(request: RemoteConfigRequest, context: EvaluatorContext) throws -> RemoteConfigParameter.TargetRule?
}

class DefaultRemoteConfigTargetRuleDeterminer: RemoteConfigTargetRuleDeterminer {

    private let matcher: RemoteConfigTargetRuleMatcher

    init(matcher: RemoteConfigTargetRuleMatcher) {
        self.matcher = matcher
    }

    func determineTargetRuleOrNil(request: RemoteConfigRequest, context: EvaluatorContext) throws -> RemoteConfigParameter.TargetRule? {
        try request.parameter.targetRules.first { it in
            try matcher.matches(request: request, context: context, targetRule: it)
        }
    }
}


protocol RemoteConfigTargetRuleMatcher {
    func matches(request: RemoteConfigRequest, context: EvaluatorContext, targetRule: RemoteConfigParameter.TargetRule) throws -> Bool
}

class DefaultRemoteConfigTargetRuleMatcher: RemoteConfigTargetRuleMatcher {

    private let targetMatcher: TargetMatcher
    private let buckter: Bucketer

    init(targetMatcher: TargetMatcher, buckter: Bucketer) {
        self.targetMatcher = targetMatcher
        self.buckter = buckter
    }

    func matches(request: RemoteConfigRequest, context: EvaluatorContext, targetRule: RemoteConfigParameter.TargetRule) throws -> Bool {
        guard try targetMatcher.matches(request: request, context: context, target: targetRule.target) else {
            return false
        }

        guard let identifier = request.user.identifiers[request.parameter.identifierType] else {
            return false
        }

        guard let bucket = request.workspace.getBucketOrNil(bucketId: targetRule.bucketId) else {
            throw HackleError.error("Bucket[\(targetRule.bucketId)]")
        }

        return buckter.bucketing(bucket: bucket, identifier: identifier) != nil
    }
}
