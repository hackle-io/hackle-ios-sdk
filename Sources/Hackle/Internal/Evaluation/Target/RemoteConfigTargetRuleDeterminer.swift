//
//  RemoteConfigTargetRuleDeterminer.swift
//  Hackle
//
//  Created by yong on 2022/11/24.
//

import Foundation


protocol RemoteConfigTargetRuleDeterminer {
    func determineTargetRuleOrNil(workspace: Workspace, parameter: RemoteConfigParameter, user: HackleUser) throws -> RemoteConfigParameter.TargetRule?
}

class DefaultRemoteConfigTargetRuleDeterminer: RemoteConfigTargetRuleDeterminer {

    private let matcher: RemoteConfigTargetRuleMatcher

    init(matcher: RemoteConfigTargetRuleMatcher) {
        self.matcher = matcher
    }

    func determineTargetRuleOrNil(workspace: Workspace, parameter: RemoteConfigParameter, user: HackleUser) throws -> RemoteConfigParameter.TargetRule? {
        try parameter.targetRules.first { it in
            try matcher.matches(targetRule: it, workspace: workspace, parameter: parameter, user: user)
        }
    }
}


protocol RemoteConfigTargetRuleMatcher {
    func matches(targetRule: RemoteConfigParameter.TargetRule, workspace: Workspace, parameter: RemoteConfigParameter, user: HackleUser) throws -> Bool
}

class DefaultRemoteConfigTargetRuleMatcher: RemoteConfigTargetRuleMatcher {

    private let targetMatcher: TargetMatcher
    private let buckter: Bucketer

    init(targetMatcher: TargetMatcher, buckter: Bucketer) {
        self.targetMatcher = targetMatcher
        self.buckter = buckter
    }

    func matches(targetRule: RemoteConfigParameter.TargetRule, workspace: Workspace, parameter: RemoteConfigParameter, user: HackleUser) throws -> Bool {
        guard try targetMatcher.matches(target: targetRule.target, workspace: workspace, user: user) else {
            return false
        }

        guard let identifier = user.identifiers[parameter.identifierType] else {
            return false
        }

        guard let bucket = workspace.getBucketOrNil(bucketId: targetRule.bucketId) else {
            throw HackleError.error("Bucket[\(targetRule.bucketId)]")
        }

        return buckter.bucketing(bucket: bucket, identifier: identifier) != nil
    }
}
