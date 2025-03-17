import Foundation

class Database {
    private let lock: ReadWriteLock
    private let filepath: String?
    private(set) var version: Int

    init(label: String, filename: String, version: Int) {
        self.lock = ReadWriteLock(label: label)
        let manager = FileManager.default
        let url = manager.urls(for: .libraryDirectory, in: .userDomainMask).last
        filepath = url?.appendingPathComponent(filename).path
        self.version = version

        let currentVersion = self.getVersion()
        // 현재 버전이 0이면 DB 생성이 안되어 있거나, 버전 명시가 안된 구버전 DB 이다
        // 구버전 DB의 마이그레이션은 onCreate에서 직접 진행해야 한다.
        if currentVersion == Database.DEFAULT_VERSION {
            onCreate()
        } else if currentVersion < self.version {
            onUpdate(oldVersion: currentVersion, newVersion: self.version)
        }
        
        // 테이블 생성/업데이트 완료 후 버전을 DB에 반영
        setVersion()
    }
    
    func execute<T>(command: (SQLiteDatabase) throws -> T) rethrows -> T {
        try lock.write {
            try SQLiteDatabase(databasePath: filepath).use { database in
                try command(database)
            }
        }
    }
    
    /// table을 생성해야할 때 호출됩니다.
    ///
    /// 이 메소드를 override하여 table을 생성합니다.
    func onCreate() {
        // nothing to do
    }
    
    /// version이 변경되었을 때 호출됩니다.
    ///
    /// 이 메소드를 override하여 version 변경 시 수행할 작업을 정의합니다.
    func onUpdate(oldVersion: Int, newVersion: Int) {
        // nothing to do
    }

    /// 현재 database의 version을 가져옵니다.
    ///
    /// - Returns: 현재 database의 version
    private func getVersion() -> Int {
        do {
            return try execute { database in
                let version = try database.queryForInt(sql: Database.GET_USER_VERSION)
                return version
            }
        } catch {
            return Database.DEFAULT_VERSION
        }
    }

    /// database의 version을 변경합니다.
    ///
    /// 임의로 버전을 파라미터로 받지 않고, `version` 을 사용합니다.
    private func setVersion() {
        do {
            try execute { database in
                try database.execute(sql: String(format: Database.SET_USER_VERSION, version))
            }
        } catch {
            Log.error("Failed to set database version: \(error)")
        }
        
    }

    private static let GET_USER_VERSION = "PRAGMA user_version"
    private static let SET_USER_VERSION = "PRAGMA user_version = %d"
    private static let DEFAULT_VERSION = 0
}
