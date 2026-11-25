//
// Created by yong on 2020/12/15.
//

import Foundation
import os.log

class Log {

    private static let counters = LogLevel.allCases.associateWith { it in
        Metrics.counter(name: "log", tags: ["level": it.rawValue])
    }

    static func debug(_ msg: @autoclosure () -> String) {
        let message = msg()
        os_log("%@", log: .hackle, type: .debug, message)
        increment(.debug)
        devTools(level: "log", message: message)
    }

    static func info(_ msg: @autoclosure () -> String) {
        let message = msg()
        os_log("%{public}@", log: .hackle, type: .default, message)
        increment(.info)
        devTools(level: "log", message: message)
    }

    static func warn(_ msg: @autoclosure () -> String) {
        let message = msg()
        os_log("%{public}@", log: .hackle, type: .default, message)
        increment(.warn)
        devTools(level: "warn", message: message)
    }

    static func error(_ msg: @autoclosure () -> String) {
        let message = msg()
        os_log("%{public}@", log: .hackle, type: .error, message)
        increment(.error)
        devTools(level: "error", message: message)
    }

    private static func devTools(level: String, message: String) {
        DevToolsRegistry.eventListener()?.onLog(
            insertId: UUID().uuidString,
            level: level,
            timestamp: Date().epochMillis,
            message: message
        )
    }

    static func increment(_ level: LogLevel) {
        counters[level]?.increment()
    }
}

extension OSLog {
    static let hackle = OSLog(subsystem: "io.hackle.sdk", category: "Hackle")
}


enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warn = "WARN"
    case error = "ERROR"
}
