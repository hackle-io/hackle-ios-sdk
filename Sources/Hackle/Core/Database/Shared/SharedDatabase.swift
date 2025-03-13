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

    override func onCreate() {
        if checkIfTableExists() {
            onUpdate(oldVersion: 1, newVersion: SharedDatabase.DATABASE_VERSION)
        } else {
            super.onCreate()
            createTable()
        }
    }
    
    override func onUpdate(oldVersion: Int, newVersion: Int) {
        super.onUpdate(oldVersion: oldVersion, newVersion: newVersion)
        if newVersion <= SharedDatabase.MAX_DATABASE_VERSION {
            if oldVersion == 1 {
                migrationTableFrom1To2()
            }
        }
    }
    
    private func createTable() {
        do {
            try execute { database in
                try database.execute(
                    sql: NotificationHistoryEntity.CREATE_TABLE
                )
            }
        } catch {
            Log.error("Failed to create tables: \(error)")
        }
    }
    
    // MARK: - Migration
    
    /// table이 존재하는지 확인합니다.
    ///
    /// 마이그레이션 전 DB의 경우 버전이 명시가 안되어있어 항상 onCreate()가 호출됩니다.
    ///
    /// 그래서 table이 존재하는지 확인하고 존재한다면 마이그레이션을 진행합니다.
    /// - Returns: 존재 여부
    private func checkIfTableExists() -> Bool {
        do {
            let exist = try execute { database in
                try database.queryForInt (
                    sql: NotificationHistoryEntity.TABLE_EXISTS
                )
            }
            return exist == 1
        } catch {
            Log.error("Failed to check if table exists: \(error)")
        }
        return false
    }

    /// 버전 1에서 버전 2로 마이그레이션합니다.
    ///
    /// Journey ID, Journey Key, Journey Node ID, Campaign Type 컬럼을 추가합니다.
    private func migrationTableFrom1To2() {
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
        }
    }
}
