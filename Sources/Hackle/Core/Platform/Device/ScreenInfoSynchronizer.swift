//
//  ScreenInfoSynchronizer.swift
//  Hackle
//

import Foundation

class ScreenInfoSynchronizer: Synchronizer {
    func sync(completion: @escaping (Result<Void, Error>) -> ()) {
        Task { @MainActor in
            ScreenInfo.initialize()
            completion(.success(()))
        }
    }
}
