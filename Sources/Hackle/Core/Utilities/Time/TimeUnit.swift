//
//  TimeUnit.swift
//  Hackle
//
//  Created by yong on 2023/01/19.
//

import Foundation

enum TimeUnit {
    case nanoseconds
    case microseconds
    case milliseconds
    case seconds
}

extension TimeUnit {

    static let C0: Int64 = 1
    static let C1: Int64 = C0 * 1000
    static let C2: Int64 = C1 * 1000
    static let C3: Int64 = C2 * 1000

    func convert(_ amount: Double, to unit: TimeUnit) -> Double {
        switch self {
        case .nanoseconds: return TimeUnit.nanosToUnit(nanos: amount, unit: unit)
        case .microseconds: return TimeUnit.microsToUnit(micros: amount, unit: unit)
        case .milliseconds: return TimeUnit.millisToUnit(millis: amount, unit: unit)
        case .seconds: return TimeUnit.secondsToUnit(seconds: amount, unit: unit)
        }
    }

    static func nanosToUnit(nanos: Double, unit: TimeUnit) -> Double {
        switch unit {
        case .nanoseconds: return nanos
        case .microseconds: return nanos / Double(C1 / C0)
        case .milliseconds: return nanos / Double(C2 / C0)
        case .seconds: return nanos / Double(C3 / C0)
        }
    }

    static func microsToUnit(micros: Double, unit: TimeUnit) -> Double {
        switch unit {
        case .nanoseconds: return micros * Double(C1 / C0)
        case .microseconds: return micros
        case .milliseconds: return micros / Double(C2 / C1)
        case .seconds: return micros / Double(C3 / C1)
        }
    }

    static func millisToUnit(millis: Double, unit: TimeUnit) -> Double {
        switch unit {
        case .nanoseconds: return millis * Double(C2 / C0)
        case .microseconds: return millis * Double(C2 / C1)
        case .milliseconds: return millis
        case .seconds: return millis / Double(C3 / C2)
        }
    }

    static func secondsToUnit(seconds: Double, unit: TimeUnit) -> Double {
        switch unit {
        case .nanoseconds: return seconds * Double(C3 / C0)
        case .microseconds: return seconds * Double(C3 / C1)
        case .milliseconds: return seconds * Double(C3 / C2)
        case .seconds: return seconds
        }
    }
}
