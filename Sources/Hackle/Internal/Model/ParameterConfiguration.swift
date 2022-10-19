//
//  ParameterConfiguration.swift
//  Hackle
//
//  Created by yong on 2022/10/16.
//

import Foundation

protocol ParameterConfiguration: ParameterConfig {

    typealias Id = Int64

    var id: Id { get }
    var parameters: [String: HackleValue] { get }
}


class ParameterConfigurationEntity: ParameterConfiguration {

    let id: Id
    let parameters: [String: HackleValue]

    init(id: Id, parameters: [String: HackleValue]) {
        self.id = id
        self.parameters = parameters
    }

    func getString(forKey: String, defaultValue: String) -> String {
        parameters[forKey]?.stringOrNil ?? defaultValue
    }

    func getInt(forKey: String, defaultValue: Int) -> Int {
        guard let parameterValue = parameters[forKey]?.numberOrNil else {
            return defaultValue
        }
        return Int(parameterValue)
    }

    func getDouble(forKey: String, defaultValue: Double) -> Double {
        parameters[forKey]?.numberOrNil ?? defaultValue
    }

    func getBool(forKey: String, defaultValue: Bool) -> Bool {
        parameters[forKey]?.boolOrNil ?? defaultValue
    }
}
