//
//  MockSQLiteEventRepository.swift
//  Hackle
//
//  Created by sungwoo.yeo on 3/18/25.
//

import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class MockSQLiteEventRepository: SQLiteEventRepository {
    private let sdkKey: String

    init(sdkKey: String = "mock_test_\(UUID().uuidString)") {
        self.sdkKey = sdkKey
        super.init(database: WorkspaceDatabase(sdkKey: sdkKey))
    }

    func deleteAll() {
        let flusingEvent = findAllBy(status: .flushing)
        let pendingEvent = findAllBy(status: .pending)

        delete(events: flusingEvent)
        delete(events: pendingEvent)
    }

    func deleteDatabaseFile() {
        let manager = FileManager.default
        guard let dir = manager.urls(for: .libraryDirectory, in: .userDomainMask).last else {
            return
        }
        for suffix in ["", "-wal", "-shm"] {
            let path = dir.appendingPathComponent("\(sdkKey)_hackle.sqlite\(suffix)").path
            try? manager.removeItem(atPath: path)
        }
    }
}
