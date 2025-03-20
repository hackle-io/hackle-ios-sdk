//
//  MockSQLiteEventRepository.swift
//  Hackle
//
//  Created by sungwoo.yeo on 3/18/25.
//

import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class MockSQLiteEventRepository: SQLiteEventRepository {
    init() {
        let workspaceDatabase = DatabaseHelper.getWorkspaceDatabase(sdkKey: "mock_test_sdk_key")
        super.init(database: workspaceDatabase)
    }
    
    func deleteAll() {
        let flusingEvent = findAllBy(status: .flushing)
        let pendingEvent = findAllBy(status: .pending)
        
        delete(events: flusingEvent)
        delete(events: pendingEvent)
    }
}
