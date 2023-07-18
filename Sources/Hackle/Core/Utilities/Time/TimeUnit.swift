//
//  TimeUnit.swift
//  Hackle
//
//  Created by yong on 2023/01/19.
//

import Foundation

enum TimeUnit: String, Codable {
    case nanoseconds = "NANOSECONDS"
    case microseconds = "MICROSECONDS"
    case milliseconds = "MILLISECONDS"
    case seconds = "SECONDS"
    case minutes = "MINUTES"
    case hours = "HOURS"
    case days = "DAYS"
}

extension TimeUnit {

    static let C0: Int64 = 1
    static let C1: Int64 = C0 * 1000
    static let C2: Int64 = C1 * 1000
    static let C3: Int64 = C2 * 1000
    static let C4: Int64 = C3 * 60
    static let C5: Int64 = C4 * 60
    static let C6: Int64 = C5 * 24

    func convert(_ amount: Double, to unit: TimeUnit) -> Double {
        switch self {
        case .nanoseconds: return TimeUnit.nanosToUnit(nanos: amount, unit: unit)
        case .microseconds: return TimeUnit.microsToUnit(micros: amount, unit: unit)
        case .milliseconds: return TimeUnit.millisToUnit(millis: amount, unit: unit)
        case .seconds: return TimeUnit.secondsToUnit(seconds: amount, unit: unit)
        case .minutes: return TimeUnit.minutesToUnit(minutes: amount, unit: unit)
        case .hours: return TimeUnit.hoursToUnit(hours: amount, unit: unit)
        case .days: return TimeUnit.daysToUnit(days: amount, unit: unit)
        }
    }

    static func nanosToUnit(nanos: Double, unit: TimeUnit) -> Double {
        switch unit {
        case .nanoseconds: return nanos
        case .microseconds: return nanos / Double(C1 / C0)
        case .milliseconds: return nanos / Double(C2 / C0)
        case .seconds: return nanos / Double(C3 / C0)
        case .minutes: return nanos / Double(C4 / C0)
        case .hours: return nanos / Double(C5 / C0)
        case .days: return nanos / Double(C6 / C0)
        }
    }

    static func microsToUnit(micros: Double, unit: TimeUnit) -> Double {
        switch unit {
        case .nanoseconds: return micros * Double(C1 / C0)
        case .microseconds: return micros
        case .milliseconds: return micros / Double(C2 / C1)
        case .seconds: return micros / Double(C3 / C1)
        case .minutes: return micros / Double(C4 / C1)
        case .hours: return micros / Double(C5 / C1)
        case .days: return micros / Double(C6 / C1)
        }
    }

    static func millisToUnit(millis: Double, unit: TimeUnit) -> Double {
        switch unit {
        case .nanoseconds: return millis * Double(C2 / C0)
        case .microseconds: return millis * Double(C2 / C1)
        case .milliseconds: return millis
        case .seconds: return millis / Double(C3 / C2)
        case .minutes: return millis / Double(C4 / C2)
        case .hours: return millis / Double(C5 / C2)
        case .days: return millis / Double(C6 / C2)
        }
    }

    static func secondsToUnit(seconds: Double, unit: TimeUnit) -> Double {
        switch unit {
        case .nanoseconds: return seconds * Double(C3 / C0)
        case .microseconds: return seconds * Double(C3 / C1)
        case .milliseconds: return seconds * Double(C3 / C2)
        case .seconds: return seconds
        case .minutes: return seconds / Double(C4 / C3)
        case .hours: return seconds / Double(C5 / C3)
        case .days: return seconds / Double(C6 / C3)
        }
    }

    static func minutesToUnit(minutes: Double, unit: TimeUnit) -> Double {
        switch unit {
        case .nanoseconds: return minutes * Double(C4 / C0)
        case .microseconds: return minutes * Double(C4 / C1)
        case .milliseconds: return minutes * Double(C4 / C2)
        case .seconds: return minutes * Double(C4 / C3)
        case .minutes: return minutes
        case .hours: return minutes / Double(C5 / C4)
        case .days: return minutes / Double(C6 / C4)
        }
    }

    static func hoursToUnit(hours: Double, unit: TimeUnit) -> Double {
        switch unit {
        case .nanoseconds: return hours * Double(C5 / C0)
        case .microseconds: return hours * Double(C5 / C1)
        case .milliseconds: return hours * Double(C5 / C2)
        case .seconds: return hours * Double(C5 / C3)
        case .minutes: return hours * Double(C5 / C4)
        case .hours: return hours
        case .days: return hours / Double(C6 / C5)
        }
    }

    static func daysToUnit(days: Double, unit: TimeUnit) -> Double {
        switch unit {
        case .nanoseconds: return days * Double(C6 / C0)
        case .microseconds: return days * Double(C6 / C1)
        case .milliseconds: return days * Double(C6 / C2)
        case .seconds: return days * Double(C6 / C3)
        case .minutes: return days * Double(C6 / C4)
        case .hours: return days * Double(C6 / C5)
        case .days: return days
        }
    }
}
