////
////  PollingWorkspaceFetcherSpecs.swift
////  HackleTests
////
////  Created by yong on 2023/04/02.
////
//
//import Foundation
//import Quick
//import Nimble
//@testable import Hackle
//
//
//class PollingWorkspaceFetcherSpecs: QuickSpec {
//    override func spec() {
//
//        var httpWorkspaceFetcher: HttpWorkspaceFetcherStub!
//        var pollingScheduler: MockScheduler!
//
//        beforeEach {
//            httpWorkspaceFetcher = HttpWorkspaceFetcherStub()
//            pollingScheduler = MockScheduler()
//        }
//
//        describe("initialize") {
//            it("fetch workspace") {
//                let workspace = MockWorkspace()
//                httpWorkspaceFetcher.workspace = workspace
//
//                let sut = PollingWorkspaceFetcher(httpWorkspaceFetcher: httpWorkspaceFetcher, pollingScheduler: pollingScheduler, pollingInterval: 10)
//
//                expect(sut.fetch()).to(beNil())
//
//                var initialized = false
//                sut.initialize {
//                    initialized = true
//                }
//
//                expect(sut.fetch()).to(beIdenticalTo(workspace))
//                expect(initialized) == true
//            }
//        }
//
//        describe("start") {
//            it("no polling") {
//                let workspace = MockWorkspace()
//                httpWorkspaceFetcher.workspace = workspace
//
//                let sut = PollingWorkspaceFetcher(httpWorkspaceFetcher: httpWorkspaceFetcher, pollingScheduler: pollingScheduler, pollingInterval: -1)
//
//                sut.onChanged(state: .foreground, timestamp: Date())
//
//                verify(exactly: 0) {
//                    pollingScheduler.schedulePeriodicallyMock
//                }
//                expect(sut.fetch()).to(beNil())
//            }
//
//            it("polling") {
//                let workspace = MockWorkspace()
//                httpWorkspaceFetcher.workspace = workspace
//
//                let job = MockScheduledJob()
//                every(pollingScheduler.schedulePeriodicallyMock).returns(job)
//
//                let sut = PollingWorkspaceFetcher(httpWorkspaceFetcher: httpWorkspaceFetcher, pollingScheduler: pollingScheduler, pollingInterval: 42)
//
//                sut.onChanged(state: .foreground, timestamp: Date())
//
//                verify {
//                    pollingScheduler.schedulePeriodicallyMock
//                }
//                pollingScheduler.schedulePeriodicallyMock.firstInvokation().arguments.2()
//                expect(sut.fetch()).to(beIdenticalTo(workspace))
//            }
//        }
//
//        describe("stop") {
//            it("polling") {
//                let workspace = MockWorkspace()
//                httpWorkspaceFetcher.workspace = workspace
//
//                let job = MockScheduledJob()
//                every(pollingScheduler.schedulePeriodicallyMock).returns(job)
//
//                let sut = PollingWorkspaceFetcher(httpWorkspaceFetcher: httpWorkspaceFetcher, pollingScheduler: pollingScheduler, pollingInterval: 42)
//
//                sut.onChanged(state: .foreground, timestamp: Date())
//
//                verify {
//                    pollingScheduler.schedulePeriodicallyMock
//                }
//                pollingScheduler.schedulePeriodicallyMock.firstInvokation().arguments.2()
//                expect(sut.fetch()).to(beIdenticalTo(workspace))
//
//                sut.onChanged(state: .background, timestamp: Date())
//                verify(exactly: 1) {
//                    job.cancelMock
//                }
//            }
//        }
//    }
//
//    private class HttpWorkspaceFetcherStub: HttpWorkspaceFetcher {
//        var workspace: Workspace? = nil
//
//        func fetchIfModified(completion: @escaping (Workspace?, Error?) -> ()) {
//            completion(workspace, nil)
//        }
//    }
//}
