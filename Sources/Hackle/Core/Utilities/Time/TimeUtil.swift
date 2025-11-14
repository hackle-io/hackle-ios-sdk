//
//  TimeUtil.swift
//  Hackle
//
//  Created by sungwoo.yeo on 11/14/25.
//

import Foundation

class TimeUtil {
    private static var utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
            if let utcTimeZone = TimeZone(secondsFromGMT: 0) {
                calendar.timeZone = utcTimeZone
            }
        return calendar
    }()
    
    static func dayOfWeek(_ timestamp: Date) -> DayOfWeek? {
        let dayOfWeek = utcCalendar.component(.weekday, from: timestamp)

        switch dayOfWeek {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default:
            return nil
        }
    }
    
    static func midnight(_ timestamp: Date) -> Date {
        return utcCalendar.startOfDay(for: timestamp)
    }
}
