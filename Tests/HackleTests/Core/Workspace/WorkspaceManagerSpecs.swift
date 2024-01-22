import Foundation
import Nimble
import Quick
import Mockery
@testable import Hackle


class WorkspaceManagerSpecs: QuickSpec {
    override func spec() {
        it("nil workspace data returns if not sync called") {
            let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [])
            let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, workspaceFile: MockFile())
            let actual = sut.fetch()
            
            expect(actual).to(beNil())
        }
        
        it("workspace data return and write to file") {
            let json = try! String(contentsOfFile: Bundle(for: WorkspaceManagerSpecs.self)
                .path(forResource: "workspace_config", ofType: "json")!)
            let data = try! JSONDecoder().decode(WorkspaceConfig.self, from: json.data(using: .utf8)!)
            let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [data])
            let mockFile = MockFile()
            let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, workspaceFile: mockFile)
            
            sut.sync { }
            
            let actual = sut.fetch()
            expect(actual?.id) == data.config.workspace.id
            expect(actual?.environmentId) == data.config.workspace.environment.id
            expect(mockFile.currentData).toNot(beNil())
            expect(mockFile.writeHistories.count) == 1
        }
        
        it("workspace data returns from file") {
            let json = try! String(contentsOfFile: Bundle(for: WorkspaceManagerSpecs.self)
                .path(forResource: "workspace_config", ofType: "json")!)
            let data = try! JSONDecoder().decode(WorkspaceConfig.self, from: json.data(using: .utf8)!)
            let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [])
            let mockFile = MockFile(initialData: json)
            let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, workspaceFile: mockFile)
        
            let actual = sut.fetch()
            expect(actual?.id) == data.config.workspace.id
            expect(actual?.environmentId) == data.config.workspace.environment.id
        }
        
        it("overwrite workspace file") {
            let json = try! String(contentsOfFile: Bundle(for: WorkspaceManagerSpecs.self)
                .path(forResource: "workspace_config", ofType: "json")!)
            let data = try! JSONDecoder().decode(WorkspaceConfig.self, from: json.data(using: .utf8)!)
            let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [data])
            let mockFile = MockFile(initialData: json)
            let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, workspaceFile: mockFile)
        
            sut.sync { }
            
            let actual = sut.fetch()
            expect(actual?.id) == data.config.workspace.id
            expect(actual?.environmentId) == data.config.workspace.environment.id
            expect(mockFile.writeHistories.count) == 1
        }
        
        it("overwrite even though invalid json file already exists") {
            let json = try! String(contentsOfFile: Bundle(for: WorkspaceManagerSpecs.self)
                .path(forResource: "workspace_config", ofType: "json")!)
            let mockFile = MockFile(initialData: "{!")
            let data = try! JSONDecoder().decode(WorkspaceConfig.self, from: json.data(using: .utf8)!)
            let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [data])
            let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, workspaceFile: mockFile)
        
            sut.sync { }
            
            let actual = sut.fetch()
            expect(actual?.id) == data.config.workspace.id
            expect(actual?.environmentId) == data.config.workspace.environment.id
            expect(mockFile.writeHistories.count) == 1
        }
        
        it("last modified with second http request") {
            let firstJson = try! String(contentsOfFile: Bundle(for: WorkspaceManagerSpecs.self)
                .path(forResource: "workspace_config", ofType: "json")!)
            let first = try! JSONDecoder().decode(WorkspaceConfig.self, from: firstJson.data(using: .utf8)!)
            
            let secondJson = try! String(contentsOfFile: Bundle(for: WorkspaceManagerSpecs.self)
                .path(forResource: "workspace_config", ofType: "json")!)
            let second = try! JSONDecoder().decode(WorkspaceConfig.self, from: secondJson.data(using: .utf8)!)
            
            let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [first, second])
            let mockFile = MockFile()
            let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, workspaceFile: mockFile)
            
            sut.sync { }
            sut.sync { }
            
            expect(httpWorkspaceFetcher.fetchIfModifiedRef.lastInvokation().arguments.0) == second.lastModified
        }
        
        it("not change workspace file if http request returns nil") {
            let json = try! String(contentsOfFile: Bundle(for: WorkspaceManagerSpecs.self)
                .path(forResource: "workspace_config", ofType: "json")!)
            let data = try! JSONDecoder().decode(WorkspaceConfig.self, from: json.data(using: .utf8)!)
            let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [nil])
            let mockFile = MockFile(initialData: json)
            let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, workspaceFile: mockFile)
        
            sut.sync { }
            
            let actual = sut.fetch()
            expect(actual?.id) == data.config.workspace.id
            expect(actual?.environmentId) == data.config.workspace.environment.id
            expect(mockFile.writeHistories.count) == 0
        }
        
        it("not any exception even though workspace file is nil") {
            let json = try! String(contentsOfFile: Bundle(for: WorkspaceManagerSpecs.self)
                .path(forResource: "workspace_config", ofType: "json")!)
            let data = try! JSONDecoder().decode(WorkspaceConfig.self, from: json.data(using: .utf8)!)
            let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [data])
            let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, workspaceFile: nil)
            
            sut.sync { }
            
            let actual = sut.fetch()
            expect(actual?.id) == data.config.workspace.id
            expect(actual?.environmentId) == data.config.workspace.environment.id
        }
        
        it("not any exception even though error occours while http request calling") {
            let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [HackleError.error("fail")])
            let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, workspaceFile: MockFile())
            
            sut.sync { }
            
            let actual = sut.fetch()
            expect(actual).to(beNil())
        }
        
        it("not overwrite workspace file even though error occours while http request calling") {
            let json = try! String(contentsOfFile: Bundle(for: WorkspaceManagerSpecs.self)
                .path(forResource: "workspace_config", ofType: "json")!)
            let mockFile = MockFile(initialData: json)
            let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [HackleError.error("fail")])
            let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, workspaceFile: mockFile)
            
            sut.sync { }
            
            let actual = sut.fetch()
            expect(actual).toNot(beNil())
            expect(mockFile.writeHistories.count) == 0
        }
    }
}


private class MockHttpWorkspaceFetcher: Mock, HttpWorkspaceFetcher {

    private let returns: [Any?]
    private var count = 0

    init(returns: [Any?]) {
        self.returns = returns
    }

    
    lazy var fetchIfModifiedRef = MockFunction(self, fetchIfModified)
    func fetchIfModified(lastModified: String?, completion: @escaping (Result<WorkspaceConfig?, Error>) -> ()) {
        call(fetchIfModifiedRef, args: (lastModified, completion))
        
        let value = returns[count]
        count += 1

        switch value {
        case let config as WorkspaceConfig:
            completion(.success(config))
            break
        case let error as Error:
            completion(.failure(error))
            break
        default:
            completion(.success(nil))
        }
    }
}
