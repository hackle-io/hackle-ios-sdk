//
// Created by yong on 2020/12/15.
//

import Foundation
import os.log

class Log {

    private static let tags: [LogLevel: [String: String]] =
        LogLevel.allCases.associateWith { ["level": $0.rawValue] }

    static func debug(_ msg: @autoclosure () -> String) {
        os_log("%@", log: .hackle, type: .debug, msg())
        increment(.debug)
    }

    static func info(_ msg: @autoclosure () -> String) {
        os_log("%{public}@", log: .hackle, type: .default, msg())
        increment(.info)
    }

    static func error(_ msg: @autoclosure () -> String) {
        os_log("%{public}@", log: .hackle, type: .error, msg())
        increment(.error)
    }

    static func increment(_ level: LogLevel) {
        Metrics.counter(name: "log", tags: tags[level] ?? ["level": level.rawValue]) { $0.increment() }
    }
}

extension OSLog {
    static let hackle = OSLog(subsystem: "io.hackle.sdk", category: "Hackle")
}


enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case error = "ERROR"
}
