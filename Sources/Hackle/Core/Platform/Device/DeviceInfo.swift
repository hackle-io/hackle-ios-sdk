//
//  DeviceInfo.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/4/25.
//

import Foundation

struct DeviceInfo {
    let osName: String
    let osVersion: String
    let model: String
    let type: String
    let brand: String
    let manufacturer: String
    let locale: Locale
    let timezone: TimeZone
    let screenInfo: ScreenInfo
}

struct ScreenInfo {
    let width: Int
    let height: Int
}
