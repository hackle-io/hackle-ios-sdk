//
//  UserTarget.swift
//  Hackle
//
//  Created by sungwoo.yeo on 2/7/25.
//

struct UserTarget {
    let userTargetEvents: UserTargetEvents
    let userCohorts: UserCohorts
}

extension UserTarget {
    static func from(dto: UserTargetResponseDto) -> UserTarget {
        UserTarget(
            userTargetEvents: UserTargetEvents.from(dto: dto),
            userCohorts: UserCohorts.from(dto: dto)
        )
    }
}
