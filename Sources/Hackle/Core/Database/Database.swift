import Foundation

class Database {
    private let lock: ReadWriteLock
    private let filepath: String?
    private(set) var version: Int
    private let versionRepository = UserDefaultsKeyValueRepository.of(suiteName: storageSuiteNameVersion)

    init(label: String, filename: String, version: Int) {
        self.lock = ReadWriteLock(label: label)
        let manager = FileManager.default
        let url = manager.urls(for: .libraryDirectory, in: .userDomainMask).last
        self.filepath = url?.appendingPathComponent(filename).path
        self.version = version

        do {
            // 항상 create 호출
            // 단, create 할 때 if exist 필수
            try onCreate()
            
            let currentVersion = getVersion(key: filename)
            if currentVersion < version {
                try onMigration(oldVersion: currentVersion, newVersion: version)
            }
        } catch {
            Log.error("drop and recreate database \(label), because of error: \(error)")
            onDrop()
            onCreateLatest()
        }

        setVersion(key: filename)
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
    /// 이 메소드에서는 **반드시** v1 버전의 table을 생성해야 합니다.
    ///
    /// v1 이후의 버전 데이터 반영은 `onMigration(oldVersion: Int, newVersion: Int)` 에서 수행합니다.
    ///
    /// - Throws: table 생성에 실패했을 때 발생하는 error
    func onCreate() throws {
        fatalError("onCreate() has not been implemented")
    }
    
    /// 마이그레이션 해야할 때 호출합니다.
    ///
    /// 테이블 최초 생성 시, version이 변경되었을 시 모두 호출됩니다.
    ///
    /// 이 메소드를 override하여 마이그레이션에서 수행할 작업을 정의합니다.
    /// - Parameters:
    ///  - oldVersion: 이전 버전
    ///  - newVersion: 새 버전
    /// - Throws: 마이그레이션에 실패했을 때 발생하는 error
    func onMigration(oldVersion: Int, newVersion: Int) throws {
        fatalError("onMigration(oldVersion: Int, newVersion: Int) has not been implemented")
    }
    
    /// database를 삭제해야할 때 호출됩니다.
    ///
    /// 이 메소드를 override하여 database를 삭제합니다.
    func onDrop() {
        fatalError("onDrop() has not been implemented")
    }
    
    /// 최신 버전의 table을 생성해야할 때 호출됩니다.
    ///
    /// **반드시 drop table 후에만 호출**해야 합니다.
    ///
    /// 이 메소드를 override하여 최신 버전의 table을 생성합니다.
    func onCreateLatest() {
        fatalError("onCreateLatest() has not been implemented")
    }

    /// 현재 database의 version을 가져옵니다.
    ///
    /// - Returns: 현재 database의 version
    func getVersion(key: String) -> Int {
        return versionRepository.getInteger(key: key)
    }

    /// database의 version을 변경합니다.
    ///
    /// 임의로 버전을 파라미터로 받지 않고, `version` 을 사용합니다.
    private func setVersion(key: String) {
        versionRepository.putInteger(key: key, value: version)
    }

    static let DEFAULT_VERSION = 0
}
