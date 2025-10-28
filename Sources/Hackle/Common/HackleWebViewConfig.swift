//
//  HackleWebViewConfig.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/28/25.
//

import Foundation

@objc public class HackleWebViewConfig: NSObject {
    let automaticScreenTracking: Bool
    let automaticEngagementTracking: Bool
    
    @objc public static let DEFAULT: HackleWebViewConfig = builder().build()

    init(_ builder: HackleWebViewConfigBuilder) {
        self.automaticScreenTracking = builder.automaticScreenTracking
        self.automaticEngagementTracking = builder.automaticEngagementTracking
        super.init()
    }
    
    @objc public static func builder() -> HackleWebViewConfigBuilder {
        HackleWebViewConfigBuilder()
    }
}

@objc public class HackleWebViewConfigBuilder: NSObject {
    var automaticScreenTracking: Bool = false
    var automaticEngagementTracking: Bool = false
    
    @discardableResult
    @objc public func automaticScreenTracking(_ automaticTracking: Bool) -> HackleWebViewConfigBuilder {
        self.automaticScreenTracking = automaticTracking
        return self
    }
    
    @discardableResult
    @objc public func automaticEngagementTracking(_ automaticTracking: Bool) -> HackleWebViewConfigBuilder {
        self.automaticEngagementTracking = automaticTracking
        return self
    }
    
    @objc public func build() -> HackleWebViewConfig {
        return HackleWebViewConfig(self)
    }
}
