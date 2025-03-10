import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultWorkspaceConfigRepositorySpecs: QuickSpec {
    func readTextFromRes(filename: String) -> String {
        return try! String(contentsOfFile: Bundle(for: DefaultWorkspaceConfigRepositorySpecs.self).path(forResource: filename, ofType: "json")!)
    }
    
    override func spec() {
        it("get") {
            let initialData = self.readTextFromRes(filename: "workspace_config")
            let mockFileStorage = MockFileStorage(
                initialData: ["workspace.json": initialData.data(using: .utf8)!]
            )
            let repository = DefaultWorkspaceConfigRepository(fileStorage: mockFileStorage)
            
            
            expect(repository.get()?.lastModified) == "Tue, 16 Jan 2024 07:39:44 GMT"
            expect(repository.get()?.config.workspace.id) == 3
            expect(repository.get()?.config.workspace.environment.id) == 5
        }
        
        it("get nil") {
            let mockFileStorage = MockFileStorage()
            let repository = DefaultWorkspaceConfigRepository(fileStorage: mockFileStorage)
            expect(repository.get()).to(beNil())
        }
        
        it("set") {
            let mockFileStorage = MockFileStorage()
            let repository = DefaultWorkspaceConfigRepository(fileStorage: mockFileStorage)
            
            expect(repository.get()).to(beNil())
            
            let json = self.readTextFromRes(filename: "workspace_config")
            let data = try! JSONDecoder().decode(WorkspaceConfig.self, from: json.data(using: .utf8)!)
            repository.set(value: data)
            
            expect(repository.get()?.lastModified) == "Tue, 16 Jan 2024 07:39:44 GMT"
        }
        
        it("overwrite") {
            let initialData = self.readTextFromRes(filename: "workspace_config")
            let mockFileStorage = MockFileStorage(
                initialData: ["workspace.json": initialData.data(using: .utf8)!]
            )
            let repository = DefaultWorkspaceConfigRepository(fileStorage: mockFileStorage)
            
            expect(repository.get()?.lastModified) == "Tue, 16 Jan 2024 07:39:44 GMT"
            
            let modifiedData = self.readTextFromRes(filename: "workspace_config_modified")
            let data = try! JSONDecoder().decode(WorkspaceConfig.self, from: modifiedData.data(using: .utf8)!)
            repository.set(value: data)
            
            expect(repository.get()?.lastModified) == "Mon, 22 Jan 2024 08:37:33 GMT"
        }
        
        it("delete file if invalid json file exists") {
            let mockFileStorage = MockFileStorage(
                initialData: ["workspace.json": "{!".data(using: .utf8)!]
            )
            let repository = DefaultWorkspaceConfigRepository(fileStorage: mockFileStorage)
            
            expect(repository.get()).to(beNil())
            expect(mockFileStorage.data["workspace.json"]).to(beNil())
        }
    }
}
