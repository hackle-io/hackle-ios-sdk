import Foundation

class WorkspaceDatabase: Database {
    static let DATABASE_VERSION = 1
    static let MAX_DATABASE_VERSION = 1

    init(sdkKey: String) {
        super.init(
            label: "io.hackle.WorkspaceDatabase",
            filename: "\(sdkKey)_hackle.sqlite",
            version: WorkspaceDatabase.DATABASE_VERSION
        )
    }
    
    override func onCreate() throws {
        try createTable()
    }

    override func onMigration(oldVersion: Int, newVersion: Int) throws {
    }
    
    override func onDrop() {
    }
    
    override func onCreateLatest() {
        try? createTable()
    }
    
    private func createTable() throws {
        do {
            try execute { database in
                try database.execute(
                    sql: EventEntity.CREATE_TABLE
                )
            }
        } catch {
            Log.error("Failed to create tables: \(error)")
            throw error
        }
    }
    
    private func dropTable() {
        do {
            try execute { database in
                try database.execute(
                    sql: EventEntity.DROP_TABLE
                )
            }
        } catch {
            Log.error("Failed to delete tables: \(error)")
        }
    }
}
