//
//  ApplicationInstallStateManager.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/8/25.
//

import Foundation

class ApplicationInstallStateManager {
    
    private let clock: Clock
    private let queue: DispatchQueue
    private var applicationInstallDeterminer: ApplicationInstallDeterminer
    private var listeners: [ApplicationInstallStateListener] = []
    
    init(clock: Clock, queue: DispatchQueue, applicationInstallDeterminer: ApplicationInstallDeterminer) {
        self.clock = clock
        self.queue = queue
        self.applicationInstallDeterminer = applicationInstallDeterminer
    }
    
    func addListener(listener: ApplicationInstallStateListener) {
        listeners.append(listener)
    }
    
    func checkApplicationInstall() {
        let state = applicationInstallDeterminer.determine()
        execute {
            if state != .none {
                Log.debug("ApplicationInstallStateManager.checkApplicationInstall(\(state))")
                let timestamp = self.clock.now()
                if state == .install {
                    self.publishInstall(timestamp: timestamp)
                } else if state == .update {
                    self.publishUpdate(timestamp: timestamp)
                }
            }
        }
    }
    
    private func publishInstall(timestamp: Date) {
        for listener in listeners {
            listener.onInstall(timestamp: timestamp)
        }
    }
    
    private func publishUpdate(timestamp: Date) {
        for listener in listeners {
            listener.onUpdate(timestamp: timestamp)
        }
    }
    
    private func execute(_ action: @escaping () -> Void) {
        queue.async(execute: action)
    }
}
