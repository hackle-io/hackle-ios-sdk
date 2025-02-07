//
//  UserContext.swift
//  Hackle
//
//  Created by yong on 2023/10/03.
//

import Foundation


struct UserContext: CustomStringConvertible {
    let user: User
    let cohorts: UserCohorts
    let targetEvents: UserTargetEvents

    private init(user: User, cohorts: UserCohorts, targetEvents: UserTargetEvents) {
        self.user = user
        self.cohorts = cohorts
        self.targetEvents = targetEvents
    }

    var description: String {
        "UserContext(user: \(user), cohorts: \(cohorts))"
    }
}

extension UserContext {

    static func of(user: User, cohorts: UserCohorts, targetEvents: UserTargetEvents) -> UserContext {
        UserContext(user: user, cohorts: cohorts.filterBy(user: user), targetEvents: targetEvents)
    }
}

extension UserContext {
    func with(user: User) -> UserContext {
        let filtered = cohorts.filterBy(user: user)
        return UserContext.of(user: user, cohorts: filtered, targetEvents: targetEvents)
    }

    func update(cohorts: UserCohorts, targetEvents: UserTargetEvents) -> UserContext {
        let filtered = cohorts.filterBy(user: self.user)
        let newCohorts = cohorts.toBuilder()
            .putAll(cohorts: filtered)
            .build()
        let newTargetEvents = targetEvents.toBuilder()
            .putAll(targetEvents: targetEvents)
            .build()
        return UserContext.of(user: self.user, cohorts: newCohorts, targetEvents: newTargetEvents)
    }
}
