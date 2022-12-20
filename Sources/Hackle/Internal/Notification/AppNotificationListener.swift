//
// Created by yong on 2020/12/11.
//

import Foundation

protocol AppNotificationListener {
    func onNotified(notification: AppNotification, timestamp: Date)
}
