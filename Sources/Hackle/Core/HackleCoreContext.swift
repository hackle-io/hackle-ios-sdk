//
//  HackleCoreContext.swift
//  Hackle
//

import Foundation


class HackleCoreContext: @unchecked Sendable {

    static let shared = HackleCoreContext()

    private var instances = [Any]()

    func get<T>(_ type: T.Type) -> T? {
        instances.first { instance in
            instance is T
        } as? T
    }

    func register(_ instance: Any) {
        instances.append(instance)
    }

    static func create() -> HackleCoreContext {
        HackleCoreContext()
    }
}
