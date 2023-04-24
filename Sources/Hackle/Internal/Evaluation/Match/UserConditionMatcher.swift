//
//  UserConditionMatcher.swift
//  Hackle
//
//  Created by yong on 2023/04/17.
//

import Foundation

class UserConditionMatcher: ConditionMatcher {

    private let userValueResolver: UserValueResolver
    private let valueOperatorMatcher: ValueOperatorMatcher

    init(userValueResolver: UserValueResolver, valueOperatorMatcher: ValueOperatorMatcher) {
        self.userValueResolver = userValueResolver
        self.valueOperatorMatcher = valueOperatorMatcher
    }

    func matches(request: EvaluatorRequest, context: EvaluatorContext, condition: Target.Condition) throws -> Bool {
        guard let userValue = try userValueResolver.resolveOrNil(user: request.user, key: condition.key) else {
            return false
        }
        return valueOperatorMatcher.matches(userValue: userValue, match: condition.match)
    }
}

protocol UserValueResolver {
    func resolveOrNil(user: HackleUser, key: Target.Key) throws -> Any?
}

class DefaultUserValueResolver: UserValueResolver {
    func resolveOrNil(user: HackleUser, key: Target.Key) throws -> Any? {
        switch key.type {
        case .userId:
            return user.identifiers[key.name]
        case .userProperty:
            return user.properties[key.name]
        case .hackleProperty:
            return user.hackleProperties[key.name]
        case .segment, .abTest, .featureFlag:
            throw HackleError.error("Unsupported TargetKeyType [\(key.type)]")
        }
    }
}