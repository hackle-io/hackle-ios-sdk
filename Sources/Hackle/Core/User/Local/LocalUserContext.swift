//
//  LocalUserContext.swift
//  Hackle
//
//  Created by yong on 2023/10/03.
//

import Foundation


struct LocalUserContext: UserContext, CustomStringConvertible {
    let user: User
    let cohorts: UserCohorts
    let targetEvents: UserTargetEvents

    private init(user: User, cohorts: UserCohorts, targetEvents: UserTargetEvents) {
        self.user = user
        self.cohorts = cohorts
        self.targetEvents = targetEvents
    }

    var description: String {
        "LocalUserContext(user: \(user), cohorts: \(cohorts))"
    }
}

extension LocalUserContext {

    static func of(user: User, cohorts: UserCohorts, targetEvents: UserTargetEvents) -> LocalUserContext {
        LocalUserContext(user: user, cohorts: cohorts.filterBy(user: user), targetEvents: targetEvents)
    }
}

extension LocalUserContext {
    func with(user: User) -> LocalUserContext {
        let filtered = cohorts.filterBy(user: user)
        return LocalUserContext.of(user: user, cohorts: filtered, targetEvents: targetEvents)
    }

    func update(cohorts: UserCohorts) -> LocalUserContext {
        let filtered = cohorts.filterBy(user: self.user)
        let newCohorts = self.cohorts.toBuilder()
            .putAll(cohorts: filtered)
            .build()
        return LocalUserContext.of(user: self.user, cohorts: newCohorts, targetEvents: targetEvents)
    }

    func update(targetEvents: UserTargetEvents) -> LocalUserContext {
        return LocalUserContext.of(user: self.user, cohorts: cohorts, targetEvents: targetEvents)
    }
}
