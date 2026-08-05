import Foundation
import Quick
import Nimble
@testable import Hackle


/// WorkspaceConfigManager.context에 대한 data race 재현 스펙.
/// -enableThreadSanitizer YES 로 실행할 것.
class WorkspaceConfigManagerRaceSpecs: QuickSpec {
    override class func spec() {

        it("WorkspaceConfigManager: concurrent context write (sync) vs read (workspace/metadata)") {
            let data = WorkspaceConfigManagerSpecs.loadWorkspaceConfigFromRes()
            let fetcher = FixedHttpWorkspaceConfigFetcher(context: data)
            let repository = MockWorkspaceConfigRepository()
            let sut = WorkspaceConfigManager(httpWorkspaceConfigFetcher: fetcher, repository: repository)
            sut.initialize()

            let writerIterations = 2_000
            let readerCount = 4
            let readerIterations = 15_000
            let group = DispatchGroup()
            let user = HackleUser.of(userId: "user")

            DispatchQueue.global(qos: .utility).async(group: group) {
                for _ in 0..<writerIterations {
                    let sem = DispatchSemaphore(value: 0)
                    Task {
                        try? await sut.sync()
                        sem.signal()
                    }
                    sem.wait()
                }
            }

            for _ in 0..<readerCount {
                DispatchQueue.global(qos: .utility).async(group: group) {
                    for _ in 0..<readerIterations {
                        let _: WorkspaceConfig? = sut.workspace(user: user)
                        _ = sut.metadata()
                    }
                }
            }

            group.wait()

            expect(sut.metadata()?.id) == 3
        }
    }
}

private final class FixedHttpWorkspaceConfigFetcher: HttpWorkspaceConfigFetcher {
    private let context: WorkspaceConfigContext

    init(context: WorkspaceConfigContext) {
        self.context = context
    }

    func fetchIfModified(lastModified: String?) async throws -> WorkspaceConfigContext? {
        context
    }
}
