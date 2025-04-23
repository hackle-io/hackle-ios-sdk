//
//  HackleNotificationHandleType.swift
//  Hackle
//
//  Created by sungwoo.yeo on 4/22/25.
//

import Foundation

/// Hackle Push Notification Click Action 처리 방법
@objc public enum HackleNotificationHandleType: Int, RawRepresentable {
    /// app open or deep link 모두 처리
    case open
    /// deep link의 경우 푸시 클릭 이벤트만 수집하고 link open은 무시
    ///
    /// ignoreOpenLink의 경우 직접 deep link 처리를 해야 합니다.
    case ignoreOpenLink
}
