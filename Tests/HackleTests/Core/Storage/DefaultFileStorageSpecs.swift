import Foundation
import Nimble
import Quick
@testable import Hackle

class DefaultFileStorageSpecs: QuickSpec {
    override func spec() {
        let sdkKey = "abcd1234"
        let libPath = try! FileManager.default
            .url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let hackleDirPath = libPath.appendingPathComponent("hackle/\(sdkKey)")
        
        afterEach {
            try? FileManager.default.removeItem(atPath: hackleDirPath.path)
        }
        
        it("create sdk seperated directory") {
            _ = try! DefaultFileStorage(sdkKey: sdkKey)
            expect(FileManager.default.fileExists(atPath: hackleDirPath.path)) == true
        }
        
        it("do nothing even directory already exists") {
            try! FileManager.default.createDirectory(at: hackleDirPath, withIntermediateDirectories: true)
            _ = try! DefaultFileStorage(sdkKey: sdkKey)
        }
        
        it("write single file") {
            let fileStorage = try! DefaultFileStorage(sdkKey: sdkKey)
            
            let inputFileText = "abcd"
            let inputFilePath = "text.txt"
            try! fileStorage.write(filename: inputFilePath, data: inputFileText.data(using: .utf8)!)
            
            let targetPath = hackleDirPath.appendingPathComponent(inputFilePath)
            let targetFileText = try! String(contentsOf: targetPath, encoding: .utf8)
            
            expect(targetFileText) == inputFileText
        }
        
        it("write single file into sub directory") {
            let fileStorage = try! DefaultFileStorage(sdkKey: sdkKey)
            
            let inputFileText = "abcd"
            let inputFilePath = "sub/text.txt"
            try! fileStorage.write(filename: inputFilePath, data: inputFileText.data(using: .utf8)!)
            
            let targetPath = hackleDirPath.appendingPathComponent(inputFilePath)
            let targetFileText = try! String(contentsOf: targetPath, encoding: .utf8)
            
            expect(targetFileText) == inputFileText
        }
        
        it("read single file") {
            let fileStorage = try! DefaultFileStorage(sdkKey: sdkKey)
            
            let filePath = hackleDirPath.appendingPathComponent("text.txt")
            let fileText = "abcd"
            try! fileText.data(using: .utf8)?.write(to: filePath)
            
            let data = try! fileStorage.read(filename: "text.txt")
            let readText = String(data: data, encoding: .utf8)
            
            expect(readText) == fileText
        }
        
        it("read single file into sub directory") {
            let fileStorage = try! DefaultFileStorage(sdkKey: sdkKey)
            
            let filePath = hackleDirPath.appendingPathComponent("sub/text.txt")
            let subdirectoryPath = filePath.deletingLastPathComponent()
            try? FileManager.default.createDirectory(atPath: subdirectoryPath.path, withIntermediateDirectories: true)
            let fileText = "abcd"
            try! fileText.data(using: .utf8)?.write(to: filePath)
            
            let data = try! fileStorage.read(filename: "sub/text.txt")
            let readText = String(data: data, encoding: .utf8)
            
            expect(readText) == fileText
        }
    }
}
