import Foundation
import Nimble
import Quick
import MockingKit
@testable import Hackle

class WorkspaceConfigManagerSpecs: AsyncSpec {
    static func loadWorkspaceConfigFromRes(filename: String = "workspace_config") -> WorkspaceConfigContext {
        let json = try! String(contentsOfFile: Bundle(for: WorkspaceConfigManagerSpecs.self).path(forResource: filename, ofType: "json")!)
        let dto = try! JSONDecoder().decode(WorkspaceConfigRecordDto.self, from: json.data(using: .utf8)!)
        return WorkspaceConfigContext.from(dto: dto)
    }

    override class func spec() {
        it("nil workspace data returns if not sync called and no saved data") {
            let httpWorkspaceConfigFetcher = MockHttpWorkspaceConfigFetcher(returns: [])
            let repository = MockWorkspaceConfigRepository()
            let sut = WorkspaceConfigManager(httpWorkspaceConfigFetcher: httpWorkspaceConfigFetcher, repository: repository)
            sut.initialize()

            let actual: WorkspaceConfig? = sut.workspace(user: HackleUser.of(userId: "user"))
            expect(actual).to(beNil())
        }

        it("workspace data returns and write to repository") {
            let data = loadWorkspaceConfigFromRes()
            let httpWorkspaceConfigFetcher = MockHttpWorkspaceConfigFetcher(returns: [data])
            let repository = MockWorkspaceConfigRepository()
            let sut = WorkspaceConfigManager(httpWorkspaceConfigFetcher: httpWorkspaceConfigFetcher, repository: repository)
            sut.initialize()

            await awaitCompletion { try await sut.sync() }

            let actual: WorkspaceConfig? = sut.workspace(user: HackleUser.of(userId: "user"))
            expect(actual?.metadata.id) == data.dto.workspace.id
            expect(actual?.metadata.environmentId) == data.dto.workspace.environment.id
            expect(repository.value).toNot(beNil())
            expect(repository.value?.modifiedAt) == "Tue, 16 Jan 2024 07:39:44 GMT"
            expect(repository.value?.dto.workspace.id) == 3
        }

        it("workspace data returns from repository") {
            let data = loadWorkspaceConfigFromRes()
            let httpWorkspaceConfigFetcher = MockHttpWorkspaceConfigFetcher(returns: [])
            let repository = MockWorkspaceConfigRepository(value: data)
            let sut = WorkspaceConfigManager(httpWorkspaceConfigFetcher: httpWorkspaceConfigFetcher, repository: repository)
            sut.initialize()

            let actual: WorkspaceConfig? = sut.workspace(user: HackleUser.of(userId: "user"))
            expect(actual?.metadata.id) == repository.value?.dto.workspace.id
            expect(actual?.metadata.environmentId) == repository.value?.dto.workspace.environment.id
        }

        it("workspace data returns from repository after initialize") {
            let data = loadWorkspaceConfigFromRes()
            let httpWorkspaceConfigFetcher = MockHttpWorkspaceConfigFetcher(returns: [])
            let repository = MockWorkspaceConfigRepository(value: data)
            let sut = WorkspaceConfigManager(httpWorkspaceConfigFetcher: httpWorkspaceConfigFetcher, repository: repository)

            expect(sut.workspace(user: HackleUser.of(userId: "user")) as WorkspaceConfig?).to(beNil())

            sut.initialize()

            let actual: WorkspaceConfig? = sut.workspace(user: HackleUser.of(userId: "user"))
            expect(actual?.metadata.id) == repository.value?.dto.workspace.id
            expect(actual?.metadata.environmentId) == repository.value?.dto.workspace.environment.id
        }

        it("write repository workspace value") {
            let data = loadWorkspaceConfigFromRes()
            let httpWorkspaceConfigFetcher = MockHttpWorkspaceConfigFetcher(returns: [data])
            let repository = MockWorkspaceConfigRepository()
            let sut = WorkspaceConfigManager(httpWorkspaceConfigFetcher: httpWorkspaceConfigFetcher, repository: repository)
            sut.initialize()

            await awaitCompletion { try await sut.sync() }

            let actual: WorkspaceConfig? = sut.workspace(user: HackleUser.of(userId: "user"))
            expect(actual?.metadata.id) == data.dto.workspace.id
            expect(actual?.metadata.environmentId) == data.dto.workspace.environment.id
            expect(repository.value).toNot(beNil())
            expect(repository.value?.modifiedAt) == data.modifiedAt
            expect(repository.value?.dto.workspace.id) == 3
        }

        it("change last modified value after sync call") {
            let first = loadWorkspaceConfigFromRes()
            let second = loadWorkspaceConfigFromRes(filename: "workspace_config_modified")
            let httpWorkspaceConfigFetcher = MockHttpWorkspaceConfigFetcher(returns: [first, second])
            let repository = MockWorkspaceConfigRepository()
            let sut = WorkspaceConfigManager(httpWorkspaceConfigFetcher: httpWorkspaceConfigFetcher, repository: repository)
            sut.initialize()

            await awaitCompletion { try await sut.sync() }

            expect(httpWorkspaceConfigFetcher.fetchIfModifiedRef.lastInvokation().arguments).to(beNil())
            expect(repository.value?.modifiedAt) == first.modifiedAt

            await awaitCompletion { try await sut.sync() }

            expect(httpWorkspaceConfigFetcher.fetchIfModifiedRef.lastInvokation().arguments) == first.modifiedAt
            expect(repository.value?.modifiedAt) == second.modifiedAt
        }

        it("do nothing if http request returns nil") {
            let data = loadWorkspaceConfigFromRes()
            let httpWorkspaceConfigFetcher = MockHttpWorkspaceConfigFetcher(returns: [nil])
            let repository = MockWorkspaceConfigRepository(value: data)
            let sut = WorkspaceConfigManager(httpWorkspaceConfigFetcher: httpWorkspaceConfigFetcher, repository: repository)
            sut.initialize()

            await awaitCompletion { try await sut.sync() }

            let actual: WorkspaceConfig? = sut.workspace(user: HackleUser.of(userId: "user"))
            expect(actual?.metadata.id) == data.dto.workspace.id
            expect(actual?.metadata.environmentId) == data.dto.workspace.environment.id
        }

        it("do nothing even http request occours error") {
            let httpWorkspaceConfigFetcher = MockHttpWorkspaceConfigFetcher(returns: [HackleError.error("fail")])
            let repository = MockWorkspaceConfigRepository()
            let sut = WorkspaceConfigManager(httpWorkspaceConfigFetcher: httpWorkspaceConfigFetcher, repository: repository)
            sut.initialize()

            await awaitCompletion { try await sut.sync() }

            let actual: WorkspaceConfig? = sut.workspace(user: HackleUser.of(userId: "user"))
            expect(actual).to(beNil())
            expect(repository.value).to(beNil())
        }

        it("do not overwrite workspace value even http request occours error") {
            let data = loadWorkspaceConfigFromRes()
            let httpWorkspaceConfigFetcher = MockHttpWorkspaceConfigFetcher(returns: [HackleError.error("fail")])
            let repository = MockWorkspaceConfigRepository(value: data)
            let sut = WorkspaceConfigManager(httpWorkspaceConfigFetcher: httpWorkspaceConfigFetcher, repository: repository)
            sut.initialize()

            await awaitCompletion { try await sut.sync() }

            let actual: WorkspaceConfig? = sut.workspace(user: HackleUser.of(userId: "user"))
            expect(actual).toNot(beNil())
            expect(repository.value).toNot(beNil())
            expect(repository.value?.modifiedAt) == data.modifiedAt
            expect(repository.value?.dto.workspace.id) == 3
        }

        it("metadata returns nil before workspace loaded") {
            let httpWorkspaceConfigFetcher = MockHttpWorkspaceConfigFetcher(returns: [])
            let repository = MockWorkspaceConfigRepository()
            let sut = WorkspaceConfigManager(httpWorkspaceConfigFetcher: httpWorkspaceConfigFetcher, repository: repository)
            sut.initialize()

            expect(sut.metadata()).to(beNil())
        }

        it("metadata returns workspace metadata after initialize with saved data") {
            let context = loadWorkspaceConfigFromRes()
            let httpWorkspaceConfigFetcher = MockHttpWorkspaceConfigFetcher(returns: [])
            let repository = MockWorkspaceConfigRepository(value: context)
            let sut = WorkspaceConfigManager(httpWorkspaceConfigFetcher: httpWorkspaceConfigFetcher, repository: repository)
            sut.initialize()

            expect(sut.metadata()?.id) == 3
            expect(sut.metadata()?.environmentId) == 5
        }
    }
}
