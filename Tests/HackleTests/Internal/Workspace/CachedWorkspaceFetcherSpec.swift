//
// Created by yong on 2020/12/22.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class CachedWorkspaceFetcherSpec: QuickSpec {
    override func spec() {
        var httpWorkspaceFetcher: MockHttpWorkspaceFetcher!
        var sut: CachedWorkspaceFetcher!

        beforeEach {
            httpWorkspaceFetcher = MockHttpWorkspaceFetcher()
            sut = CachedWorkspaceFetcher(httpWorkspaceFetcher: httpWorkspaceFetcher)
        }

        describe("fetchFromServer") {

            it("httpFetcher가 넘겨준 workspace를 설정한다") {
                // given
                let workspace = MockWorkspace()
                httpWorkspaceFetcher.workspace = workspace

                // when
                sut.fetchFromServer {
                }

                // then
                expect(sut.getWorkspaceOrNil()).to(beIdenticalTo(workspace))
            }

            it("httpFetcher가 nil을 넘겨주면 workspace를 설정하지 않는다") {
                // given
                httpWorkspaceFetcher.workspace = nil

                // when
                sut.fetchFromServer {
                }

                // then
                expect(sut.getWorkspaceOrNil()).to(beNil())
            }

            it("콜백으로 넘긴 completion이 실행되어야 한다") {
                // given
                var mark = false

                // when
                sut.fetchFromServer {
                    mark = true
                }

                // then
                expect(mark) == true
            }
        }
    }
}

class MockHttpWorkspaceFetcher: HttpWorkspaceFetcher {

    var workspace: Workspace? = nil

    func fetch(completion: @escaping (Workspace?) -> ()) {
        completion(workspace)
    }
}