//
//  EvaluationContext.swift
//  Hackle
//
//  Created by yong on 2023/06/01.
//

import Foundation


class EvaluationContext: @unchecked Sendable {

    static let shared = EvaluationContext()

    private var instances = [Any]()

    func get<T>(_ type: T.Type) -> T? {
        instances.first { instance in
            instance is T
        } as? T
    }

    func register(_ instance: Any) {
        instances.append(instance)
    }
}
