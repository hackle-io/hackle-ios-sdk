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
}


class ParameterConfigurationEntity: ParameterConfiguration {

    let id: Id
    let parameters: [String: Any]
    private let _parameters: [String: HackleValue]

    init(id: Id, parameters: [String: HackleValue]) {
        self.id = id
        self._parameters = parameters
        self.parameters = parameters.compactMapValues { it in
            it.rawValue
        }
    }

    func getString(forKey: String, defaultValue: String) -> String {
        _parameters[forKey]?.stringOrNil ?? defaultValue
    }

    func getInt(forKey: String, defaultValue: Int) -> Int {
        _parameters[forKey]?.doubleOrNil?.toIntOrNil() ?? defaultValue
    }

    func getDouble(forKey: String, defaultValue: Double) -> Double {
        _parameters[forKey]?.doubleOrNil ?? defaultValue
    }

    func getBool(forKey: String, defaultValue: Bool) -> Bool {
        _parameters[forKey]?.boolOrNil ?? defaultValue
    }
}

extension Double {
    func toIntOrNil() -> Int? {
        if Double(Int.min) < self && self < Double(Int.max) {
            return Int(self)
        } else {
            return nil
        }
    }
}