//
//  HackleRemoteConfig.swift
//  Hackle
//
//  Created by yong on 2022/11/25.
//

import Foundation

/// Protocol for accessing remote configuration values.
@objc
public protocol HackleRemoteConfig: Config {
    /// Gets a string value from the remote configuration.
    ///
    /// - Parameters:
    ///   - forKey: The configuration key
    ///   - defaultValue: The default value to return if the key is not found
    /// - Returns: The configuration value or the default value
    func getString(forKey: String, defaultValue: String) -> String
    
    /// Gets an integer value from the remote configuration.
    ///
    /// - Parameters:
    ///   - forKey: The configuration key
    ///   - defaultValue: The default value to return if the key is not found
    /// - Returns: The configuration value or the default value
    func getInt(forKey: String, defaultValue: Int) -> Int
    
    /// Gets a double value from the remote configuration.
    ///
    /// - Parameters:
    ///   - forKey: The configuration key
    ///   - defaultValue: The default value to return if the key is not found
    /// - Returns: The configuration value or the default value
    func getDouble(forKey: String, defaultValue: Double) -> Double
    
    /// Gets a boolean value from the remote configuration.
    ///
    /// - Parameters:
    ///   - forKey: The configuration key
    ///   - defaultValue: The default value to return if the key is not found
    /// - Returns: The configuration value or the default value
    func getBool(forKey: String, defaultValue: Bool) -> Bool
}
