//
//  Synchronizer.swift
//  Hackle
//
//  Created by yong on 2023/10/02.
//

import Foundation


protocol Synchronizer {
    func sync(completion: @escaping () -> ())
}
