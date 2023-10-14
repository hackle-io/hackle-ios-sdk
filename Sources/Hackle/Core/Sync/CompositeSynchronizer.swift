//
//  DelegatingSynchronizer.swift
//  Hackle
//
//  Created by yong on 2023/10/02.
//

import Foundation

protocol CompositeSynchronizer: Synchronizer {
    func sync(type: SynchronizerType, completion: @escaping () -> ()) throws
}


enum SynchronizerType {
    case workspace
    case cohort
}


fileprivate class Synchronization {
    let type: SynchronizerType
    let synchronizer: Synchronizer

    init(type: SynchronizerType, synchronizer: Synchronizer) {
        self.type = type
        self.synchronizer = synchronizer
    }
}

class DefaultCompositeSynchronizer: CompositeSynchronizer {

    private let dispatchQueue: DispatchQueue
    private var synchronizations: [Synchronization] = []

    init(dispatchQueue: DispatchQueue) {
        self.dispatchQueue = dispatchQueue
    }

    func add(type: SynchronizerType, synchronizer: Synchronizer) {
        self.synchronizations.append(Synchronization(type: type, synchronizer: synchronizer))
        Log.debug("Synchronizer added [\(synchronizer)]")
    }

    func sync(completion: @escaping () -> ()) {
        let dispatchGroup = DispatchGroup()
        for synchronization in synchronizations {
            dispatchGroup.enter()
            dispatchQueue.async {
                synchronization.synchronizer.sync {
                    dispatchGroup.leave()
                }
            }
        }
        dispatchGroup.notify(queue: dispatchQueue) {
            completion()
        }
    }

    func sync(type: SynchronizerType, completion: @escaping () -> ()) throws {
        guard let synchronization = synchronizations.first(where: { it in it.type == type }) else {
            throw HackleError.error("Unsupported SynchronizerType [\(type)]")
        }
        synchronization.synchronizer.sync(completion: completion)
    }
}
