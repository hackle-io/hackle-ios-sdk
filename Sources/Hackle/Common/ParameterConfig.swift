//
//  ParameterConfig.swift
//  Hackle
//
//  Created by yong on 2022/10/16.
//

import Foundation

@objc
public protocol ParameterConfig {
    func getString(forKey: String, defaultValue: String) -> String
    func getInt(forKey: String, defaultValue: Int) -> Int
    func getDouble(forKey: String, defaultValue: Double) -> Double
    func getBool(forKey: String, defaultValue: Bool) -> Bool
}

class EmptyParameterConfig: ParameterConfig {

    private init() {
    }

    static let instance = EmptyParameterConfig()

    func getString(forKey: String, defaultValue: String) -> String {
        defaultValue
    }

    func getInt(forKey: String, defaultValue: Int) -> Int {
        defaultValue
    }

    func getDouble(forKey: String, defaultValue: Double) -> Double {
        defaultValue
    }

    func getBool(forKey: String, defaultValue: Bool) -> Bool {
        defaultValue
    }
}
