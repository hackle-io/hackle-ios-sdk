//
// Created by yong on 2020/12/20.
//

import Foundation

struct Sdk {
    var key: String
    var name: String
    var version: String

    static func of(sdkKey: String, config: HackleConfig) -> Sdk {
        guard let wrapperName = config.get("$wrapper_name"),
              let wrapperVersion = config.get("$wrapper_version")
        else {
            return Sdk(key: sdkKey, name: "ios-sdk", version: SdkVersion.CURRENT)
        }
        return Sdk(key: sdkKey, name: wrapperName, version: wrapperVersion)
    }
}
