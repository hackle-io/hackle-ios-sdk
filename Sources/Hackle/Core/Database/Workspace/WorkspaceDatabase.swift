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
    
    override func getDDLs(oldVersion: Int, newVersion: Int) -> [DatabaseDDL] {
        return EventEntity.DDL_LIST
            .filter { $0.version >= oldVersion && $0.version <= newVersion }
    }

    override func onDrop() throws {
        do {
            try execute { database in
                try database.execute(
                    sql: EventEntity.DROP_TABLE
                )
            }
        } catch {
            Log.error("Failed to delete tables: \(error)")
            throw error
        }
    }
}
