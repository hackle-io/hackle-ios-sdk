//
//  Config.swift
//  Hackle
//
//  Created by yong on 2022/11/24.
//

import Foundation

// TODO: Hackle prefix를 추가하려고 했으나 기존에 "HackleConfig"가 존재함. 적당한 이름으로 변경을 추천함.
@objc public protocol Config {
    func getString(forKey: String, defaultValue: String) -> String
    func getInt(forKey: String, defaultValue: Int) -> Int
    func getDouble(forKey: String, defaultValue: Double) -> Double
    func getBool(forKey: String, defaultValue: Bool) -> Bool
}
