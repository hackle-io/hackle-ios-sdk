import Foundation
@testable import Hackle

class MockFileStorage: FileStorage {
    enum FileError: String, Error {
        case FileNotExists = "No file"
        case NoSuchFileOrDirectory = "No such file or directory"
    }

    var data: [String: Data]
    
    init(initialData: [String: Data] = [:]) {
        data = initialData
    }
    
    func exists(filename: String) -> Bool {
        return self.data.keys.contains(filename)
    }
    
    func write(filename: String, data: Data) throws {
        self.data[filename] = data
    }
    
    func read(filename: String) throws -> Data {
        guard let data = self.data[filename] else {
            throw FileError.FileNotExists
        }
        return data
    }
    
    func delete(filename: String) throws {
        self.data[filename] = nil
    }
}
