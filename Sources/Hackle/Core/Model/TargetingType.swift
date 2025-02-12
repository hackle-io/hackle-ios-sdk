//
//  TargetingType.swift
//  Hackle
//
//  Created by yong on 2022/01/28.
//

import Foundation

class TargetingType {

    private let supportedKeyTypes: [Target.KeyType]

    init(_ supportedKeyTypes: Target.KeyType...) {
        self.supportedKeyTypes = supportedKeyTypes
    }

    func supports(keyType: Target.KeyType) -> Bool {
        supportedKeyTypes.contains(keyType)
    }
}

extension TargetingType {
    static let identifier = TargetingType(.segment)
    static let property = TargetingType(.segment, .userProperty, .hackleProperty, .eventProperty, .abTest, .featureFlag, .cohort, .numberOfEventsInDays, .numberOfEventsWithPropertyInDays)
    static let segment = TargetingType(.userId, .userProperty, .hackleProperty, .cohort, .numberOfEventsInDays, .numberOfEventsWithPropertyInDays)
}
