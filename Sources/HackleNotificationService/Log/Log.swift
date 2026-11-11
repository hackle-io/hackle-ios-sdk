import Foundation
import os.log

enum Log {
    static func info(_ msg: @autoclosure () -> String) {
        os_log("%{public}@", log: .hackleNotificationService, type: .default, msg())
    }
}

extension OSLog {
    static let hackleNotificationService = OSLog(subsystem: "io.hackle.sdk", category: "HackleNotificationService")
}
