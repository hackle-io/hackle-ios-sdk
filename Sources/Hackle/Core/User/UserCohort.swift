//
//  UserCohort.swift
//  Hackle
//
//  Created by yong on 2023/10/03.
//

import Foundation


struct UserCohort: Equatable, CustomStringConvertible {
    let identifier: Identifier
    let cohorts: [Cohort]

    init(identifier: Identifier, cohorts: [Cohort]) {
        self.identifier = identifier
        self.cohorts = cohorts
    }

    var description: String {
        "UserCohort(identifier: \(identifier), cohorts: \(cohorts))"
    }
}

typealias UserCohorts = [Identifier: UserCohort]

extension UserCohorts {

    var rawCohorts: [Cohort] {
        values.flatMap { it in
            it.cohorts
        }
    }

    func toBuilder() -> Builder {
        Builder(cohorts: self)
    }

    func filterBy(user: User) -> UserCohorts {
        let identifiers = user.resolvedIdentifiers
        return filter { (key, _) in
            identifiers.contains(identifier: key)
        }
    }
}

extension UserCohorts {

    static func empty() -> UserCohorts {
        [:]
    }

    static func builder() -> Builder {
        Builder()
    }

    static func from(dto: UserCohortsResponseDto) -> UserCohorts {
        dto.cohorts.reduce(builder()) { builder, cohort in
                builder.put(cohort: UserCohort(
                    identifier: Identifier(type: cohort.identifier.type, value: cohort.identifier.value),
                    cohorts: cohort.cohorts.map({ Cohort(id: $0) })
                ))
            }
            .build()
    }
    
    static func from(dto: UserTargetResponseDto) -> UserCohorts {
        dto.cohorts.reduce(builder()) { builder, cohort in
                builder.put(cohort: UserCohort(
                    identifier: Identifier(type: cohort.identifier.type, value: cohort.identifier.value),
                    cohorts: cohort.cohorts.map({ Cohort(id: $0) })
                ))
            }
            .build()
    }

    class Builder {

        private var cohorts = UserCohorts()

        init() {
        }

        init(cohorts: UserCohorts) {
            self.cohorts.merge(cohorts) { _, new in
                new
            }
        }

        func put(cohort: UserCohort) -> Builder {
            cohorts[cohort.identifier] = cohort
            return self
        }

        func putAll(cohorts: UserCohorts) -> Builder {
            self.cohorts.merge(cohorts) { _, new in
                new
            }
            return self
        }

        func build() -> UserCohorts {
            cohorts
        }
    }
}
