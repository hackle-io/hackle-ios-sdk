import Foundation

class Database {
    private let lock: ReadWriteLock
    private let filepath: String?
    private(set) var version: Int
    private let userDefaults = UserDefaults.standard

    init(label: String, filename: String, version: Int) {
        self.lock = ReadWriteLock(label: label)
        let manager = FileManager.default
        let url = manager.urls(for: .libraryDirectory, in: .userDomainMask).last
        self.filepath = url?.appendingPathComponent(filename).path
        self.version = version

        do {
            let currentVersion = getVersion(label: label)
            if currentVersion == Database.DEFAULT_VERSION {
                try onCreate()
            }
            
            if currentVersion < version {
                try onMigration(oldVersion: currentVersion, newVersion: version)
            }
        } catch {
            Log.error("drop and recreate database \(label), because of error: \(error)")
            onDrop()
            onCreateLatest()
        }

        setVersion(label: label)
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
    
    /// table을 생성해야할 때 호출됩니다.
    ///
    /// override하여 table을 생성합니다.
    ///
    /// 이 메소드에서는 **반드시** v1 버전의 table을 생성해야 합니다.<br/>
    /// v1 이후의 버전 데이터 반영은 `onMigration(oldVersion: Int, newVersion: Int)` 에서 수행합니다.
    ///
    /// - Throws: table 생성에 실패했을 때 발생하는 error
    func onCreate() throws {
        Log.error("onCreate() must be overridden")
    }
    
    /// version이 변경되었을 때 호출됩니다.
    ///
    /// 이 메소드를 override하여 version 변경 시 수행할 작업을 정의합니다.
    func onMigration(oldVersion: Int, newVersion: Int) throws {
        Log.error("onMigration(oldVersion: Int, newVersion: Int) must be overridden")
    }
    
    /// database를 삭제해야할 때 호출됩니다.
    func onDrop() {
        Log.error("onDrop() must be overridden")
    }
    
    /// 최신 버전의 table을 생성해야할 때 호출됩니다.
    ///
    /// 반드시 drop table 후에만 호출해야 합니다.
    func onCreateLatest() {
        Log.error("onCreateLatest() must be overridden")
    }

    /// 현재 database의 version을 가져옵니다.
    ///
    /// - Returns: 현재 database의 version
    private func getVersion(label: String) -> Int {
        return userDefaults.integer(forKey: label)
    }

    /// database의 version을 변경합니다.
    ///
    /// 임의로 버전을 파라미터로 받지 않고, `version` 을 사용합니다.
    private func setVersion(label: String) {
        userDefaults.set(version, forKey: label)
        
    }

    static let DEFAULT_VERSION = 0
}
