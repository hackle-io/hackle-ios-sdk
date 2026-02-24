//
//  DeviceInfo.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/4/25.
//

import Foundation
import UIKit

struct DeviceInfo {
    let osName: String
    let osVersion: String
    let model: String
    let type: String
    let brand: String
    let manufacturer: String
    let locale: Locale
    let timezone: TimeZone
}

struct ScreenInfo {
    let width: Int
    let height: Int

    private static let _cached = AtomicReference<ScreenInfo?>(value: nil)

    @MainActor
    static func initialize() {
        guard _cached.get() == nil else { return }
        let screen = UIUtils.currentScreen
        _cached.set(newValue: ScreenInfo(
            width: Int(screen.nativeBounds.width),
            height: Int(screen.nativeBounds.height)
        ))
    }

    static var current: ScreenInfo {
        _cached.get() ?? ScreenInfo(width: 0, height: 0)
    }
}
