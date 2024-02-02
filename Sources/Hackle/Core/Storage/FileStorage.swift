import Foundation

protocol FileStorage {
    func exists(filename: String) -> Bool
    func write(filename: String, data: Data) throws
    func read(filename: String) throws -> Data
    func delete(filename: String) throws
}

class DefaultFileStorage: FileStorage {
    private let dirPath: URL
    private let lock: ReadWriteLock
    
    init(sdkKey: String) throws {
        let libPath = try FileManager.default
            .url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        dirPath = libPath.appendingPathComponent("\(DefaultFileStorage.ROOT_DIR_NAME)/\(sdkKey)")
        try? FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true)
        lock = ReadWriteLock(label: "io.hackle.DefaultFileStorage")
    }
    
    func exists(filename: String) -> Bool {
        let filePath = createFileFullPath(filename)
        return FileManager.default.fileExists(atPath: filePath.path)
    }
    
    func write(filename: String, data: Data) throws {
        let filePath = createFileFullPath(filename)
        if filePath.pathComponents.count > 1 {
            let directoryPath = filePath.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: directoryPath, withIntermediateDirectories: true)
        }
        
        try lock.write {
            try data.write(to: filePath)
        }
    }
    
    func read(filename: String) throws -> Data {
        let filePath = createFileFullPath(filename)
        return try lock.read {
            try Data(contentsOf: filePath)
        }
    }
    
    func delete(filename: String) throws {
        let filePath = createFileFullPath(filename)
        try lock.write {
            try FileManager.default.removeItem(at: filePath)
        }
    }
    
    private func createFileFullPath(_ filename: String) -> URL {
        return dirPath.appendingPathComponent(filename)
    }
}

extension DefaultFileStorage {
    private static let ROOT_DIR_NAME = "hackle"
}
