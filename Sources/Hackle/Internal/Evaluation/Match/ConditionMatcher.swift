import Foundation

protocol ConditionMatcher {
    func matches(condition: Target.Condition, workspace: Workspace, user: HackleUser) throws -> Bool
}

protocol ConditionMatcherFactory {
    func getMatcher(_ type: Target.KeyType) -> ConditionMatcher
}

class UserConditionMatcher: ConditionMatcher {

    private let userValueResolver: UserValueResolver
    private let valueOperatorMatcher: ValueOperatorMatcher

    init(userValueResolver: UserValueResolver, valueOperatorMatcher: ValueOperatorMatcher) {
        self.userValueResolver = userValueResolver
        self.valueOperatorMatcher = valueOperatorMatcher
    }

    func matches(condition: Target.Condition, workspace: Workspace, user: HackleUser) throws -> Bool {
        guard let userValue = try userValueResolver.resolveOrNil(user: user, key: condition.key) else {
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
            return user.id
        case .userProperty:
            return user.properties?[key.name]
        case .hackleProperty:
            return user.hackleProperties?[key.name]
        case .segment:
            throw HackleError.error("Unsupported TargetKeyType [\(key.type)]")
        }
    }
}

class SegmentConditionMatcher: ConditionMatcher {

    private let segmentMatcher: SegmentMatcher

    init(segmentMatcher: SegmentMatcher) {
        self.segmentMatcher = segmentMatcher
    }

    func matches(condition: Target.Condition, workspace: Workspace, user: HackleUser) throws -> Bool {
        guard condition.key.type == .segment else {
            throw HackleError.error("Unsupported TargetKeyType [\(condition.key.type)]")
        }
        return try condition.match.values.contains { it in
            try matches(value: it, workspace: workspace, user: user)
        }
    }

    private func matches(value: MatchValue, workspace: Workspace, user: HackleUser) throws -> Bool {
        guard let segmentKey = value.stringOrNil else {
            throw HackleError.error("SegmentKey[\(value)]")
        }
        guard let segment = workspace.getSegmentOrNil(segmentKey: segmentKey) else {
            throw HackleError.error("Segment[\(segmentKey)]")
        }
        return try segmentMatcher.matches(segment: segment, workspace: workspace, user: user)
    }
}

protocol SegmentMatcher {
    func matches(segment: Segment, workspace: Workspace, user: HackleUser) throws -> Bool
}

class DefaultSegmentMatcher: SegmentMatcher {

    private let userConditionMatcher: ConditionMatcher

    init(userConditionMatcher: ConditionMatcher) {
        self.userConditionMatcher = userConditionMatcher
    }

    func matches(segment: Segment, workspace: Workspace, user: HackleUser) throws -> Bool {
        try segment.targets.contains { it in
            try matches(target: it, workspace: workspace, user: user)
        }
    }

    private func matches(target: Target, workspace: Workspace, user: HackleUser) throws -> Bool {
        try target.conditions.allSatisfy { it in
            try userConditionMatcher.matches(condition: it, workspace: workspace, user: user)
        }
    }
}

class DefaultConditionMatcherFactory: ConditionMatcherFactory {

    private let userConditionMatcher: ConditionMatcher
    private let segmentConditionMatcher: ConditionMatcher

    init() {
        userConditionMatcher =
            UserConditionMatcher(
                userValueResolver: DefaultUserValueResolver(),
                valueOperatorMatcher: DefaultValueOperatorMatcher(
                    valueMatcherFactory: ValueMatcherFactory(),
                    operatorMatcherFactory: OperatorMatcherFactory()
                )
            )

        segmentConditionMatcher = SegmentConditionMatcher(
            segmentMatcher: DefaultSegmentMatcher(userConditionMatcher: userConditionMatcher)
        )
    }


    func getMatcher(_ type: Target.KeyType) -> ConditionMatcher {
        switch type {
        case .userId, .userProperty, .hackleProperty: return userConditionMatcher
        case .segment: return segmentConditionMatcher
        }
    }
}
