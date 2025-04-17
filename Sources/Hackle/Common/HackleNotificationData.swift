//
//  HackleNotificationData.swift
//  Hackle
//
//  Created by sungwoo.yeo on 4/17/25.
//

import Foundation

@objc public final class HackleNotificationData: NSObject {
    public let campaignType: String?
    public let pushMessageKey: Int64?
    public let journeyKey: Int64?
    public let clickAction: HackleNotificationClickAction?
    public let link: String?
    
    init(
        campaignType: String?,
        pushMessageKey: Int64?,
        journeyKey: Int64?,
        clickAction: NotificationClickAction,
        link: String?
    ) {
        self.campaignType = campaignType
        self.pushMessageKey = pushMessageKey
        self.journeyKey = journeyKey
        self.clickAction = HackleNotificationClickAction(rawValue: clickAction.rawValue)
        self.link = link
    }
    
    static func from(notificationData: NotificationData) -> HackleNotificationData {
        HackleNotificationData(
            campaignType: notificationData.campaignType,
            pushMessageKey: notificationData.pushMessageKey,
            journeyKey: notificationData.journeyKey,
            clickAction: notificationData.clickAction,
            link: notificationData.link
        )
    }
}
