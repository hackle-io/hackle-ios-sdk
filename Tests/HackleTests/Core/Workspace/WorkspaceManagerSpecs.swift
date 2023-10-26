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
                let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher)

                // when
                let actual = sut.fetch()

                // then
                expect(actual).to(beNil())
            }

            it("when workspace is synced then return that workspace") {
                // given
                let workspace = MockWorkspace()
                let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [workspace])
                let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher)

                // when
                sut.sync {
                }
                let actual = sut.fetch()

                // then
                expect(actual).to(beIdenticalTo(workspace))
            }
        }

        describe("sync") {

            it("error") {
                let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [HackleError.error("fail")])
                let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher)

                // when
                sut.sync {
                }
                let actual = sut.fetch()

                // then
                expect(actual).to(beNil())
            }

            it("success") {
                // given
                let workspace = MockWorkspace()
                let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [workspace])
                let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher)

                // when
                sut.sync {
                }
                let actual = sut.fetch()

                // then
                expect(actual).to(beIdenticalTo(workspace))
            }

            it("not modified") {
                let httpWorkspaceFetcher = MockHttpWorkspaceFetcher(returns: [nil])
                let sut = WorkspaceManager(httpWorkspaceFetcher: httpWorkspaceFetcher)

                // when
                sut.sync {
                }
                let actual = sut.fetch()

                // then
                expect(actual).to(beNil())
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

    func fetchIfModified(completion: @escaping (Result<Workspace?, Error>) -> ()) {
        let value = returns[count]

        switch value {
        case let workspace as Workspace:
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