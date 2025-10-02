//
//  ApplicationLifecycleListener.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/2/25.
//

import Foundation

protocol ApplicationLifecycleListener {
    func onForeground(timestamp: Date, isFromBackground: Bool)
    func onBackground(timestamp: Date)
}
