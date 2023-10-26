//
//  Synchronizer.swift
//  Hackle
//
//  Created by yong on 2023/10/02.
//

import Foundation


protocol Synchronizer {
    func sync(completion: @escaping (Result<Void, Error>) -> ())
}

extension Synchronizer {
    func sync(completion: @escaping () -> ()) {
        sync { result in
            if case .failure(let error) = result {
                Log.error("Failed to sync: \(error)")
            }
            completion()
        }
    }
}
