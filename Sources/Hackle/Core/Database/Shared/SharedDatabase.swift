import Foundation

class SharedDatabase: Database {
    static let DATABASE_VERSION = 2
    static let MAX_DATABASE_VERSION = 2
    
    init() {
        super.init(
            label: "io.hackle.SharedDatabase",
            filename: "shared_hackle.sqlite",
            version: SharedDatabase.DATABASE_VERSION
        )
    }
    
    override func getDDLs(oldVersion: Int, newVersion: Int) -> [DatabaseDDL] {
        return NotificationHistoryEntity.DDL_LIST
            .filter { $0.version >= oldVersion && $0.version <= newVersion }
    }
    
    override func onDrop() throws {
        do {
            try execute { database in
                try database.execute(
                    sql: NotificationHistoryEntity.DROP_TABLE
                )
            }
        } catch {
            Log.error("Failed to delete tables: \(error)")
            throw error
        }
    }
}
