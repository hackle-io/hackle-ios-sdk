import Foundation
@testable import Hackle

class MockFile: FileReadWriter {
    enum FileError: String, Error {
        case NoSuchFileOrDirectory = "No such file or directory"
    }
    
    var currentData: Data? = nil
    var writeHistories: [Date: Data] = [:]
    
    init(initialData: String? = nil) {
        if let initialData = initialData {
            currentData = initialData.data(using: .utf8)
        }
    }
    
    func read() throws -> Data {
        guard let data = currentData else {
            throw FileError.NoSuchFileOrDirectory
        }
        return data
    }
    
    func write(data: Data) throws {
        writeHistories[Date()] = data
        currentData = data
    }
}
