//
// Created by yong on 2020/12/15.
//

import Foundation

extension Date {
    var epochMillis: Int64 {
        Int64(self.timeIntervalSince1970 * 1000)
    }
}

extension TimeInterval {
    func format() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 1
        return formatter.string(from: self)!
    }
}
