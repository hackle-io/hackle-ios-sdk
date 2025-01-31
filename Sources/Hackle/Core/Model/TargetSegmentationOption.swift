//
//  TargetSegmentationOption.swift
//  Hackle
//
//  Created by sungwoo.yeo on 1/31/25.
//

struct TargetSegmentationOption: Codable {
    struct TimeRange: Codable {
        let period: Int
        let timeUnit: TimeUnit
        
        var periodDays: Int {
            get {
                if timeUnit == .days {
                    period
                } else {
                    period * Self.WEEKDAY
                }
            }
        }
        
        enum TimeUnit: Codable {
            case days
            case weeks
        }
        
        private static let WEEKDAY = 7
    }
    
    struct PropertyFilter: Codable {
        let propertyKey: PropertyKey
        let match: Target.Match
    }
}
