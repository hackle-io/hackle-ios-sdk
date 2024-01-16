import Foundation
import Nimble
import Quick
@testable import Hackle


class WorkspaceManagerSpecs: QuickSpec {
    override func spec() {
        describe("fetch") {
            it("when before sync then return nil") {
                // given
                let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [])
                let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, workspaceFile: MockFile())

                // when
                let actual = sut.fetch()

                // then
                expect(actual).to(beNil())
            }

            it("when workspace is synced then return that workspace") {
                // given
                let json = try! String(contentsOfFile: Bundle(for: WorkspaceManagerSpecs.self)
                    .path(forResource: "workspace_config", ofType: "json")!)
                let config = try! JSONDecoder().decode(WorkspaceConfigDto.self, from: json.data(using: .utf8)!)
                
                let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [config])
                let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, workspaceFile: MockFile())

                // when
                sut.sync {}
                let actual = sut.fetch()
                
                // then
                expect(actual?.id) == config.workspace.id
                expect(actual?.environmentId) == config.workspace.environment.id
            }
            
            it("expect saved workspace data return") {
                let json = try! String(contentsOfFile: Bundle(for: WorkspaceManagerSpecs.self)
                    .path(forResource: "workspace_config", ofType: "json")!)
                let config = try! JSONDecoder().decode(WorkspaceConfigDto.self, from: json.data(using: .utf8)!)
                let file = MockFile(initialData: json);
                
                let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [])
                let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, workspaceFile: file)
                
                let actual = sut.fetch()
                expect(actual?.id) == config.workspace.id
                expect(actual?.environmentId) == config.workspace.environment.id
            }
            
            it("expect run correctly even workspace file is nil") {
                let json = try! String(contentsOfFile: Bundle(for: WorkspaceManagerSpecs.self)
                    .path(forResource: "workspace_config", ofType: "json")!)
                let config = try! JSONDecoder().decode(WorkspaceConfigDto.self, from: json.data(using: .utf8)!)
                
                let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [config])
                let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, workspaceFile: nil)
                
                sut.sync { }
                
                let actual = sut.fetch()
                expect(actual?.id) == config.workspace.id
                expect(actual?.environmentId) == config.workspace.environment.id
            }
        }

        describe("sync") {

            it("error case") {
                let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [HackleError.error("fail")])
                let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, workspaceFile: MockFile())

                // when
                sut.sync {
                }
                let actual = sut.fetch()

                // then
                expect(actual).to(beNil())
            }
            
            it("expect write workspace file") {
                let json = try! String(contentsOfFile: Bundle(for: WorkspaceManagerSpecs.self)
                    .path(forResource: "workspace_config", ofType: "json")!)
                let config = try! JSONDecoder().decode(WorkspaceConfigDto.self, from: json.data(using: .utf8)!)
                let file = MockFile();
                
                let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [config])
                let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, workspaceFile: file)
                
                expect(file.data).to(beNil())
                
                sut.sync { }
                
                expect(file.data).toNot(beNil())
            }
            
            it("expect overwrite workspace file") {
                let json = try! String(contentsOfFile: Bundle(for: WorkspaceManagerSpecs.self)
                    .path(forResource: "workspace_config", ofType: "json")!)
                let initialDate = Date()
                let file = MockFile(initialData: json, lastModifiedDate: initialDate);
                
                let config = try! JSONDecoder().decode(WorkspaceConfigDto.self, from: json.data(using: .utf8)!)
                let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [config])
                let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, workspaceFile: file)
                
                sut.sync { }
                
                let actual = sut.fetch()
                expect(actual?.id) == config.workspace.id
                expect(actual?.environmentId) == config.workspace.environment.id
                
                expect(file.lastModifiedDate?.timeIntervalSince1970) != initialDate.timeIntervalSince1970
            }
            
            it("expect do not change workspace file if fether returns nil") {
                let json = try! String(contentsOfFile: Bundle(for: WorkspaceManagerSpecs.self)
                    .path(forResource: "workspace_config", ofType: "json")!)
                let initialDate = Date()
                let file = MockFile(initialData: json, lastModifiedDate: initialDate);
                
                let config = try! JSONDecoder().decode(WorkspaceConfigDto.self, from: json.data(using: .utf8)!)
                let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [nil])
                let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher, workspaceFile: file)
                
                sut.sync { }
                
                let actual = sut.fetch()
                expect(actual?.id) == config.workspace.id
                expect(actual?.environmentId) == config.workspace.environment.id
                
                expect(file.lastModifiedDate?.timeIntervalSince1970) == initialDate.timeIntervalSince1970
            }
        }
    }
}


private class MockHttpWorkspaceFetcher: HttpWorkspaceFetcher {

    private let returns: [Any?]
    private var count = 0

    init(returns: [Any?]) {
        self.returns = returns
    }

    func fetchIfModified(lastModified: String?, completion: @escaping (Result<WorkspaceConfigDto?, Error>) -> ()) {
        let value = returns[count]
        count += 1

        switch value {
        case let workspace as WorkspaceConfigDto:
            completion(.success(workspace))
            break
        case let error as Error:
            completion(.failure(error))
            break
        default:
            completion(.success(nil))
        }
    }
}
