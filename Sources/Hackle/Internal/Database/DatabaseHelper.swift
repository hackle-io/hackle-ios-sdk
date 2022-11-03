//
//  DatabaseHelper.swift
//  Hackle
//
//  Created by yong on 2022/11/02.
//

import Foundation
import SQLite3

class DatabaseHelper {

    private let lock: ReadWriteLock = ReadWriteLock(label: "io.hackle.DatabaseHelper.Lock")

    private let databasePath: String?

    init(sdkKey: String) {
        let manager = FileManager.default
        let url = manager.urls(for: .libraryDirectory, in: .userDomainMask).last
        let databasePath = url?.appendingPathComponent("\(sdkKey)_hackle.sqlite").path
        self.databasePath = databasePath
        createTable()
    }

    func execute<T>(command: (SQLiteDatabase) throws -> T) rethrows -> T {
        try lock.write {
            try SQLiteDatabase(databasePath: databasePath).use { database in
                try command(database)
            }
        }
    }

    private func createTable() {
        do {
            try execute { database in
                try database.execute(sql: EventEntity.CREATE_TABLE)
            }
        } catch {
            Log.error("Failed to create tables: \(error)")
        }
    }
}
