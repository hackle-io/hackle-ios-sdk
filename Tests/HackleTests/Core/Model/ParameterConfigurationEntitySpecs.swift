//
//  ParameterConfigurationEntitySpecs.swift
//  HackleTests
//
//  Created by yong on 2022/10/18.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class ParameterConfigurationEntitySpecs: QuickSpec {

    override func spec() {

        it("ParameterConfiguration") {

            let parameterConfiguration = ParameterConfigurationEntity(
                id: 32,
                parameters: [
                    "string_key": HackleValue(value: "string_value"),
                    "empty_string_key": HackleValue(value: ""),
                    "int_key": HackleValue(value: 42.0),
                    "zero_int_key": HackleValue(value: 0),
                    "negative_int_key": HackleValue(value: -1),
                    "long_key": HackleValue(value: 320.0),
                    "long_key2": HackleValue(value: 92147483647.0),
                    "double_key": HackleValue(value: 0.42),
                    "true_boolean_key": HackleValue(value: true),
                    "false_boolean_key": HackleValue(value: false),
                ]
            )

            expect(parameterConfiguration.id) == 32

            expect(parameterConfiguration.getString(forKey: "string_key", defaultValue: "!!")) == "string_value"
            expect(parameterConfiguration.getString(forKey: "empty_string_key", defaultValue: "!!")) == ""
            expect(parameterConfiguration.getString(forKey: "invalid_key", defaultValue: "!!")) == "!!"

            expect(parameterConfiguration.getInt(forKey: "int_key", defaultValue: 999)) == 42
            expect(parameterConfiguration.getInt(forKey: "zero_int_key", defaultValue: 999)) == 0
            expect(parameterConfiguration.getInt(forKey: "negative_int_key", defaultValue: 999)) == -1
            expect(parameterConfiguration.getInt(forKey: "invalid_int_key", defaultValue: 999)) == 999
            expect(parameterConfiguration.getInt(forKey: "double_key", defaultValue: 999)) == 0

            expect(parameterConfiguration.getDouble(forKey: "double_key", defaultValue: 99.9)) == 0.42
            expect(parameterConfiguration.getDouble(forKey: "invalid_double_key", defaultValue: 99.9)) == 99.9
            expect(parameterConfiguration.getDouble(forKey: "int_key", defaultValue: 99.9)) == 42.0

            expect(parameterConfiguration.getBool(forKey: "true_boolean_key", defaultValue: false)) == true
            expect(parameterConfiguration.getBool(forKey: "false_boolean_key", defaultValue: true)) == false
            expect(parameterConfiguration.getBool(forKey: "invalid_boolean_key", defaultValue: true)) == true
        }
    }
}