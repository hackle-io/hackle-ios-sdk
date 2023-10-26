//
//  DelegatingSynchronizer.swift
//  Hackle
//
//  Created by yong on 2023/10/02.
//

import Foundation

protocol CompositeSynchronizer: Synchronizer {
    func syncOnly(type: SynchronizerType, completion: @escaping (Result<Void, Error>) -> ())
}

extension CompositeSynchronizer {
    func syncOnly(type: SynchronizerType, completion: @escaping () -> ()) {
        syncOnly(type: type) { result in
            if case .failure(let error) = result {
                Log.error("Failed to sync: \(error)")
            }
            completion()
        }
    }
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

    func sync(completion: @escaping (Result<(), Error>) -> ()) {
        let dispatchGroup = DispatchGroup()
        for synchronization in synchronizations {
            dispatchGroup.enter()
            dispatchQueue.async {
                synchronization.synchronizer.sync { result in
                    dispatchGroup.leave()
                    if case .failure(let error) = result {
                        Log.error("Failed to sync: \(error)")
                    }
                }
            }
        }
        dispatchGroup.notify(queue: dispatchQueue) {
            completion(.success(()))
        }
    }

    func syncOnly(type: SynchronizerType, completion: @escaping (Result<(), Error>) -> ()) {
        guard let synchronization = synchronizations.first(where: { it in it.type == type }) else {
            completion(.failure(HackleError.error("Unsupported SynchronizerType [\(type)]")))
            return
        }
        synchronization.synchronizer.sync(completion: completion)
    }
}
