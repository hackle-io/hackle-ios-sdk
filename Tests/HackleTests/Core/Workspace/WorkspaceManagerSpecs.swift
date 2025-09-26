import Foundation
import Nimble
import Quick
import MockingKit
@testable import Hackle

class WorkspaceManagerSpecs: QuickSpec {
    func loadWorkspaceConfigFromRes(filename: String = "workspace_config") -> WorkspaceConfig {
        let json = try! String(contentsOfFile: Bundle(for: WorkspaceManagerSpecs.self).path(forResource: filename, ofType: "json")!)
        return try! JSONDecoder().decode(WorkspaceConfig.self, from: json.data(using: .utf8)!)
    }
    
    override func spec() {
        it("nil workspace data returns if not sync called and no saved data") {
            let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [])
            let repository = MockWorkspaceConfigRepository()
            let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, repository: repository)
            sut.initialize()
            
            let actual = sut.fetch()
            expect(actual).to(beNil())
        }
        
        it("workspace data returns and write to repository") {
            let data = self.loadWorkspaceConfigFromRes()
            let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [data])
            let repository = MockWorkspaceConfigRepository()
            let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, repository: repository)
            sut.initialize()
            
            sut.sync { }
            
            let actual = sut.fetch()
            expect(actual?.id) == data.config.workspace.id
            expect(actual?.environmentId) == data.config.workspace.environment.id
            expect(repository.value).toNot(beNil())
            expect(repository.value?.lastModified) == "Tue, 16 Jan 2024 07:39:44 GMT"
            expect(repository.value?.config.workspace.id) == 3
        }
        
        it("workspace data returns from repository") {
            let data = self.loadWorkspaceConfigFromRes()
            let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [])
            let repository = MockWorkspaceConfigRepository(value: data)
            let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, repository: repository)
            sut.initialize()
        
            let actual = sut.fetch()
            expect(actual?.id) == repository.value?.config.workspace.id
            expect(actual?.environmentId) == repository.value?.config.workspace.environment.id
        }
        
        it("workspace data returns from repository after initialize") {
            let data = self.loadWorkspaceConfigFromRes()
            let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [])
            let repository = MockWorkspaceConfigRepository(value: data)
            let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, repository: repository)
            
            expect(sut.fetch()).to(beNil())
            
            sut.initialize()
        
            let actual = sut.fetch()
            expect(actual?.id) == repository.value?.config.workspace.id
            expect(actual?.environmentId) == repository.value?.config.workspace.environment.id
        }
        
        it("write repository workspace value") {
            let data = self.loadWorkspaceConfigFromRes()
            let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [data])
            let repository = MockWorkspaceConfigRepository()
            let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, repository: repository)
            sut.initialize()
            
            sut.sync { }
            
            let actual = sut.fetch()
            expect(actual?.id) == data.config.workspace.id
            expect(actual?.environmentId) == data.config.workspace.environment.id
            expect(repository.value).toNot(beNil())
            expect(repository.value?.lastModified) == data.lastModified
            expect(repository.value?.config.workspace.id) == 3
        }
        
        it("change last modified value after sync call") {
            let first = self.loadWorkspaceConfigFromRes()
            let second = self.loadWorkspaceConfigFromRes(filename: "workspace_config_modified")
            let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [first, second])
            let repository = MockWorkspaceConfigRepository()
            let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, repository: repository)
            sut.initialize()
            
            sut.sync { }
            
            expect(httpWorkspaceFetcher.fetchIfModifiedRef.lastInvokation().arguments.0).to(beNil())
            expect(repository.value?.lastModified) == first.lastModified
            
            sut.sync { }
            
            expect(httpWorkspaceFetcher.fetchIfModifiedRef.lastInvokation().arguments.0) == first.lastModified
            expect(repository.value?.lastModified) == second.lastModified
        }
        
        it("do nothing if http request returns nil") {
            let data = self.loadWorkspaceConfigFromRes()
            let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [nil])
            let repository = MockWorkspaceConfigRepository(value: data)
            let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, repository: repository)
            sut.initialize()
            
            sut.sync { }
            
            let actual = sut.fetch()
            expect(actual?.id) == data.config.workspace.id
            expect(actual?.environmentId) == data.config.workspace.environment.id
        }
        
        it("do nothing even http request occours error") {
            let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [HackleError.error("fail")])
            let repository = MockWorkspaceConfigRepository()
            let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, repository: repository)
            sut.initialize()
            
            sut.sync { }
            
            let actual = sut.fetch()
            expect(actual).to(beNil())
            expect(repository.value).to(beNil())
        }
        
        it("do not overwrite workspace value even http request occours error") {
            let data = self.loadWorkspaceConfigFromRes()
            let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [HackleError.error("fail")])
            let repository = MockWorkspaceConfigRepository(value: data)
            let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, repository: repository)
            sut.initialize()
            
            sut.sync { }
            
            let actual = sut.fetch()
            expect(actual).toNot(beNil())
            expect(repository.value).toNot(beNil())
            expect(repository.value?.lastModified) == data.lastModified
            expect(repository.value?.config.workspace.id) == 3
        }
    }
}
