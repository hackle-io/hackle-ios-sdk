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
    
    override func getDDLs() -> [DatabaseDDL] {
        return EventEntity.DDL_LIST
    }

    override func onDrop() throws {
        try execute { database in
            try database.execute(
                sql: EventEntity.DROP_TABLE
            )
        }
    }
}
