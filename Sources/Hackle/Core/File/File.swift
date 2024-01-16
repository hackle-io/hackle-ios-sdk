import Foundation

protocol FileReader {
    func read() throws -> Data
}

protocol FileWriter {
    func write(data: Data) throws
}

protocol FileReadWriter: FileReader, FileWriter { }

class File: FileReadWriter {
    private let fileUrl: URL
    private let lock: ReadWriteLock
    
    init(directory: String, filename: String) throws {
        let root = try FileManager.default
            .url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let subdirectory = root.appendingPathComponent(directory)
        try? FileManager.default.createDirectory(atPath: subdirectory.path, withIntermediateDirectories: true)
        fileUrl = subdirectory.appendingPathComponent(filename)
        lock = ReadWriteLock(label: fileUrl.path)
    }
    
    func write(data: Data) throws {
        try lock.write {
            try data.write(to: fileUrl)
        }
    }
    
    func read() throws -> Data {
        return try lock.read {
            try Data(contentsOf: fileUrl)
        }
    }
}
