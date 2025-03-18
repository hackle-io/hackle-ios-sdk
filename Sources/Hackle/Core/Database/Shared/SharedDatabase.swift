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

    override func onCreate() throws {
        try createTable()
    }
    
    override func onMigration(oldVersion: Int, newVersion: Int) throws {
        guard newVersion <= SharedDatabase.MAX_DATABASE_VERSION else {
            throw HackleError.error("Unsupported database version: \(newVersion)")
        }
        
        switch oldVersion {
        case Database.DEFAULT_VERSION, 1:
            try migrationTableFrom1To2()
            break
        default:
            throw HackleError.error("unknown database version: \(oldVersion)")
        }
    }
    
    override func onDrop() {
        dropTable()
    }
    
    override func onCreateLatest() {
        createLatestTable()
    }
    
    private func createTable() throws {
        do {
            try execute { database in
                try database.execute(
                    sql: NotificationHistoryEntity.CREATE_TABLE_V1
                )
            }
        } catch {
            Log.error("Failed to create tables: \(error)")
            throw error
        }
    }
    
    private func createLatestTable() {
        do {
            try execute { database in
                try database.execute(
                    sql: NotificationHistoryEntity.CREATE_LATEST_TABLE
                )
            }
        } catch {
            Log.error("Failed to create latest tables: \(error)")
        }
    }
    
    private func dropTable() {
        do {
            try execute { database in
                try database.execute(
                    sql: NotificationHistoryEntity.DROP_TABLE
                )
            }
        } catch {
            Log.error("Failed to delete tables: \(error)")
        }
    }
    
    // MARK: - Migration
    
    /// 버전 1에서 버전 2로 마이그레이션합니다.
    ///
    /// Journey ID, Journey Key, Journey Node ID, Campaign Type 컬럼을 추가합니다.
    private func migrationTableFrom1To2() throws {
        do {
            try execute { database in
                try database.execute(
                    sql: NotificationHistoryEntity.ADD_JOURNEY_ID
                )
            }
            
            try execute { database in
                try database.execute(
                    sql: NotificationHistoryEntity.ADD_JOURNEY_KEY
                )
            }
            
            try execute { database in
                try database.execute(
                    sql: NotificationHistoryEntity.ADD_JOURNEY_NODE_ID
                )
            }
            
            try execute { database in
                try database.execute(
                    sql: NotificationHistoryEntity.ADD_CAMPAIGN_TYPE
                )
            }
        } catch {
            Log.error("Failed to migrate tables:\n\(error)")
            throw error
        }
    }
}
