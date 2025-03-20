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
    
    override func getDDLs() -> [DatabaseDDL] {
        return NotificationHistoryEntity.DDL_LIST
    }
    
    override func onDrop() throws {
        try execute { database in
            try database.execute(
                sql: NotificationHistoryEntity.DROP_TABLE
            )
        }
    }
}
