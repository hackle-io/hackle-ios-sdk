//
//  DispatchQueueExtensions.swift
//  HackleTests
//
//  Created by yong on 2023/01/24.
//

import Foundation

extension DispatchQueue {

    static func concurrent(label: String = UUID().uuidString) -> DispatchQueue {
        DispatchQueue(label: label, attributes: .concurrent)
    }

    func await() {
        sync(flags: .barrier) {
        }
    }
}