import Foundation

class Database {
    private let lock: ReadWriteLock
    private let filepath: String?
    private(set) var version: Int
    private let versionRepository = UserDefaultsKeyValueRepository.of(suiteName: storageSuiteNameDatabaseVersion)

    init(label: String, filename: String, version: Int) {
        self.lock = ReadWriteLock(label: label)
        let manager = FileManager.default
        let url = manager.urls(for: .libraryDirectory, in: .userDomainMask).last
        self.filepath = url?.appendingPathComponent(filename).path
        self.version = version

        do {
            let currentVersion = getVersion(key: filename)
            try executeDDLs(oldVersion: currentVersion, newVersion: version)
        } catch {
            do {
                Log.error("drop and recreate database \(label), because of error: \(error)")
                try onDrop()
                try executeDDLs(oldVersion: Database.DEFAULT_VERSION, newVersion: version)
            } catch {
                Log.error("failed to create database \(label), because of error: \(error)")
                setVersion(key: filename, version: Database.DEFAULT_VERSION)
                return
            }
        }

        setVersion(key: filename, version: self.version)
    }
    
    /// 쿼리를 실행합니다.
    /// - Parameter command: 쿼리
    /// - Returns: 리턴값
    func execute<T>(command: (SQLiteDatabase) throws -> T) rethrows -> T {
        try lock.write {
            try SQLiteDatabase(databasePath: filepath).use { database in
                try command(database)
            }
        }
    }

    /// DDL을 반환합니다.
    func getDDLs() -> [DatabaseDDL] {
        fatalError("getDDL(oldVersion: Int, newVersion: Int) has not been implemented")
    }
    
    /// database를 삭제해야할 때 호출됩니다.
    ///
    /// 이 메소드를 override하여 database를 삭제합니다.
    func onDrop() throws {
        fatalError("onDrop() has not been implemented")
    }

    /// 현재 database의 version을 가져옵니다.
    ///
    /// - Returns: 현재 database의 version
    final func getVersion(key: String) -> Int {
        return versionRepository.getInteger(key: key)
    }

    /// database의 version을 변경합니다.
    ///
    /// 임의로 버전을 파라미터로 받지 않고, `version` 을 사용합니다.
    private func setVersion(key: String, version: Int) {
        versionRepository.putInteger(key: key, value: version)
    }
    
    /// oldVersion ~ newVersion까지의 DDL을 실행합니다.
    /// - Parameters:
    ///   - oldVersion: ddl 반영 직전 버전 (ddl 반영 x)
    ///   - newVersion: ddl을 반영 할 최신 버전
    private func executeDDLs(oldVersion: Int, newVersion: Int) throws {
        let ddls = getDDLs()
            .filter { $0.version > oldVersion && $0.version <= newVersion }
        
        for ddl in ddls {
            for query in ddl.statements {
                try execute { database in
                    try database.execute(
                        sql: query
                    )
                }
            }
        }
    }

    static let DEFAULT_VERSION = 0
}
