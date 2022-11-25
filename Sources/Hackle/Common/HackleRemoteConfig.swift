//
//  HackleRemoteConfig.swift
//  Hackle
//
//  Created by yong on 2022/11/25.
//

import Foundation

@objc
public protocol HackleRemoteConfig: Config {
    func getString(forKey: String, defaultValue: String) -> String
    func getInt(forKey: String, defaultValue: Int) -> Int
    func getDouble(forKey: String, defaultValue: Double) -> Double
    func getBool(forKey: String, defaultValue: Bool) -> Bool
}
