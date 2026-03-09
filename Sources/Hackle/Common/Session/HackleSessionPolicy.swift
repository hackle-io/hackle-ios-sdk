//
//  HackleSessionPolicy.swift
//  Hackle
//

import Foundation

@objc public class HackleSessionPolicy: NSObject, @unchecked Sendable {

    @objc public let persistCondition: HackleSessionPersistCondition
    @objc public let timeoutCondition: HackleSessionTimeoutCondition

    init(
        persistCondition: HackleSessionPersistCondition,
        timeoutCondition: HackleSessionTimeoutCondition
    ) {
        self.persistCondition = persistCondition
        self.timeoutCondition = timeoutCondition
        super.init()
    }

    @objc public static func builder() -> HackleSessionPolicyBuilder {
        HackleSessionPolicyBuilder()
    }

    @objc public func toBuilder() -> HackleSessionPolicyBuilder {
        HackleSessionPolicyBuilder()
            .persistCondition(persistCondition)
            .timeoutCondition(timeoutCondition)
    }

    @objc public static let DEFAULT = HackleSessionPolicy(
        persistCondition: .ALWAYS_NEW_SESSION,
        timeoutCondition: .DEFAULT
    )
}

@objc public class HackleSessionPolicyBuilder: NSObject {

    private var _persistCondition: HackleSessionPersistCondition = .ALWAYS_NEW_SESSION
    private var _timeoutCondition: HackleSessionTimeoutCondition = .DEFAULT

    @discardableResult
    @objc public func persistCondition(_ persistCondition: HackleSessionPersistCondition) -> HackleSessionPolicyBuilder {
        self._persistCondition = persistCondition
        return self
    }

    @discardableResult
    @objc public func timeoutCondition(_ timeoutCondition: HackleSessionTimeoutCondition) -> HackleSessionPolicyBuilder {
        self._timeoutCondition = timeoutCondition
        return self
    }

    @objc public func build() -> HackleSessionPolicy {
        HackleSessionPolicy(
            persistCondition: _persistCondition,
            timeoutCondition: _timeoutCondition
        )
    }
}
