//
//  ApplicationLifecyclePublisher.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/2/25.
//

protocol ApplicationLifecyclePublisher {
    func willEnterForeground()
    func didEnterBackground()
}
