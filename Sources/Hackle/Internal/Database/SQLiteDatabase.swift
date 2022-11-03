//
//  SQLiteDatabase.swift
//  Hackle
//
//  Created by yong on 2022/11/02.
//

import Foundation
import SQLite3


class SQLiteDatabase: SQLiteCloseable {

    var connection: OpaquePointer?

    init(databasePath: String?) throws {
        if sqlite3_open(databasePath, &connection) != SQLITE_OK {
            let message = "Failed to open database: \(String(cString: sqlite3_errmsg(connection)))"
            sqlite3_close(connection)
            throw HackleError.error(message)
        }
    }

    func statement(sql: String) throws -> SQLiteStatement {
        try SQLiteStatement(database: self, sql: sql)
    }

    func query(sql: String) throws -> SQLiteCursor {
        try SQLiteCursor(database: self, sql: sql)
    }

    func queryForInt(sql: String) throws -> Int {
        try statement(sql: sql).use { statement in
            try statement.queryForInt()
        }
    }

    func execute(sql: String) throws {
        try statement(sql: sql).use { statement in
            try statement.execute()
        }
    }

    func close() {
        sqlite3_close(connection)
        connection = nil
    }
}


class SQLiteStatement: SQLiteCloseable {

    private let database: SQLiteDatabase
    private let sql: String
    private var statement: OpaquePointer?

    init(database: SQLiteDatabase, sql: String) throws {
        self.database = database
        self.sql = sql
        if sqlite3_prepare_v2(database.connection, sql, -1, &statement, nil) != SQLITE_OK {
            throw HackleError.error("Failed to prepare SQLiteStatement: \(String(cString: sqlite3_errmsg(database.connection))) \"\(sql)\"")
        }
    }

    private let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
    private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    func bindInt(index: Int32, value: Int32) throws {
        if sqlite3_bind_int(statement, index, value) != SQLITE_OK {
            throw HackleError.error("Failed to bind int: \(String(cString: sqlite3_errmsg(database.connection))) [index: \(index), value: \(value)]")
        }
    }

    func bindString(index: Int32, value: String) throws {
        if sqlite3_bind_text(statement, index, (value as NSString).utf8String, -1, SQLITE_STATIC) != SQLITE_OK {
            throw HackleError.error("Failed to bind String: \(String(cString: sqlite3_errmsg(database.connection))) [index: \(index), value: \(value)]")
        }
    }

    func execute() throws {
        if sqlite3_step(statement) != SQLITE_DONE {
            throw HackleError.error("Failed to execute statement: \(String(cString: sqlite3_errmsg(database.connection))) \"\(sql)\"")
        }
    }

    func queryForInt() throws -> Int {
        if sqlite3_step(statement) != SQLITE_ROW {
            throw HackleError.error("Failed to query")
        }
        return Int(sqlite3_column_int(statement, 0))
    }

    func close() {
        sqlite3_finalize(statement)
    }
}

class SQLiteCursor: SQLiteCloseable {

    private let database: SQLiteDatabase
    private let sql: String
    private var statement: OpaquePointer?

    init(database: SQLiteDatabase, sql: String) throws {
        self.database = database
        self.sql = sql
        if sqlite3_prepare_v2(database.connection, sql, -1, &statement, nil) != SQLITE_OK {
            throw HackleError.error("Failed to prepare SQLiteCursor: \(String(cString: sqlite3_errmsg(database.connection))) \"\(sql)\"")
        }
    }

    func moveToNext() -> Bool {
        sqlite3_step(statement) == SQLITE_ROW
    }

    func getInt(_ columnIndex: Int32) -> Int {
        Int(sqlite3_column_int(statement, columnIndex))
    }

    func getInt64(_ columnIndex: Int32) -> Int64 {
        sqlite3_column_int64(statement, columnIndex)
    }

    func getString(_ columnIndex: Int32) -> String {
        String(cString: sqlite3_column_text(statement, columnIndex))
    }

    func close() {
        sqlite3_finalize(statement)
    }
}

protocol SQLiteCloseable {
    func close()
}

extension SQLiteCloseable {
    func use<T>(block: (Self) throws -> T) rethrows -> T {
        defer  {
            close()
        }
        return try block(self)
    }
}
