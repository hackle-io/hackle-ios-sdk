import Foundation

class Database {
    private let lock: ReadWriteLock
    private let filepath: String?
    
    init(label: String, filename: String) {
        self.lock = ReadWriteLock(label: label)
        let manager = FileManager.default
        let url = manager.urls(for: .libraryDirectory, in: .userDomainMask).last
        filepath = url?.appendingPathComponent(filename).path
    }
    
    func execute<T>(command: (SQLiteDatabase) throws -> T) rethrows -> T {
        try lock.write {
            try SQLiteDatabase(databasePath: filepath).use { database in
                try command(database)
            }
        }
    }
}
