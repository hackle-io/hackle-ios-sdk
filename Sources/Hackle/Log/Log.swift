//
// Created by yong on 2020/12/15.
//

import Foundation
import os.log

class Log {

    static func info(_ msg: @autoclosure () -> String) {
        os_log("%@", log: .hackle, type: .info, msg())
    }
    
    static func error(_ msg: @autoclosure () -> String) {
        os_log("%@", log: .hackle, type: .error, msg())
    }
}

extension OSLog {
    static let hackle = OSLog(subsystem: "io.hackle.sdk", category: "Hackle")
}
