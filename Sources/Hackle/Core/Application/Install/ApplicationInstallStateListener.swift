//
//  ApplicationInstallStateListener.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/8/25.
//

import Foundation

protocol ApplicationInstallStateListener {
    func onInstall(timestamp: Date)
    func onUpdate(timestamp: Date)
}
