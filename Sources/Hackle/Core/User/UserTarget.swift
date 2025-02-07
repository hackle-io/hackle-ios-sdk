//
//  UserTarget.swift
//  Hackle
//
//  Created by sungwoo.yeo on 2/7/25.
//

struct UserTarget {
    let cohorts: UserCohorts
    let targetEvents: UserTargetEvents
}

extension UserTarget {
    static func from(dto: UserTargetResponseDto) -> UserTarget {
        UserTarget(
            cohorts: UserCohorts.from(dto: dto),
            targetEvents: UserTargetEvents.from(dto: dto)
        )
    }
}
