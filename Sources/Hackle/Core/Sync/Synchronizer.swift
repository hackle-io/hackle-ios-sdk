//
//  Synchronizer.swift
//  Hackle
//

import Foundation


protocol Synchronizer {
    func sync() async throws
}

extension Synchronizer {
    func safeSync() async {
        do {
            try await sync()
        } catch {
            Log.error("Failed to sync: \(error)")
        }
    }
}
