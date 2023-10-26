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

    private init(user: User, cohorts: UserCohorts) {
        self.user = user
        self.cohorts = cohorts
    }

    var description: String {
        "UserContext(user: \(user), cohorts: \(cohorts))"
    }
}

extension UserContext {

    static func of(user: User, cohorts: UserCohorts) -> UserContext {
        UserContext(user: user, cohorts: cohorts.filterBy(user: user))
    }
}

extension UserContext {
    func with(user: User) -> UserContext {
        let filtered = cohorts.filterBy(user: user)
        return UserContext.of(user: user, cohorts: filtered)
    }

    func update(cohorts: UserCohorts) -> UserContext {
        let filtered = cohorts.filterBy(user: self.user)
        let newCohorts = cohorts.toBuilder()
            .putAll(cohorts: filtered)
            .build()
        return UserContext.of(user: self.user, cohorts: newCohorts)
    }
}
