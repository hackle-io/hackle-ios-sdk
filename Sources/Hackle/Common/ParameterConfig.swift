//
//  ParameterConfig.swift
//  Hackle
//
//  Created by yong on 2022/10/16.
//

import Foundation

@objc(HackleParameterConfig)
public protocol ParameterConfig: Config {
    var parameters: [String: Any] { get }
    func getString(forKey: String, defaultValue: String) -> String
    func getInt(forKey: String, defaultValue: Int) -> Int
    func getDouble(forKey: String, defaultValue: Double) -> Double
    func getBool(forKey: String, defaultValue: Bool) -> Bool
}

class EmptyParameterConfig: ParameterConfig {
    let parameters: [String: Any] = [:]

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
