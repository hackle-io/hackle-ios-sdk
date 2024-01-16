import Foundation
@testable import Hackle

class MockFile: FileReadWriter {
    enum FileError: String, Error {
        case NoSuchFileOrDirectory = "No such file or directory"
    }
    
    var lastModifiedDate: Date? = nil
    var data: Data? = nil
    
    init(initialData: String? = nil, lastModifiedDate: Date = Date()) {
        if let initialData = initialData {
            self.lastModifiedDate = lastModifiedDate
            data = initialData.data(using: .utf8)
        }
    }
    
    func read() throws -> Data {
        guard let data = data else {
            throw FileError.NoSuchFileOrDirectory
        }
        return data
    }
    
    func write(data: Data) throws {
        self.lastModifiedDate = Date()
        self.data = data
    }
}
