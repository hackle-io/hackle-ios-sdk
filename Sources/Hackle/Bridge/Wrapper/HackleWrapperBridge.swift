//
//  HackleWrapperBridge.swift
//  Hackle
//
//  Created by sungwoo.yeo on 5/20/25.
//

import Foundation

class WrapperBridge: HackleWrapperBridge {
    private let bridge: HackleBridge
    
    init(app: HackleApp) {
        self.bridge = HackleBridge(app: app)
    }
    
    func invoke(_ prompt: String) -> String{
        return bridge.invoke(string: prompt)
    }
}
