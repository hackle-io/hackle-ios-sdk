import Foundation
import Quick
import Nimble
@testable import Hackle

class OptOutManagerSpec: QuickSpec {
    override func spec() {

        describe("init") {
            it("config=false, saved=false이면 opt-in") {
                let repository = MemoryKeyValueRepository()
                let sut = OptOutManager(keyValueRepository: repository, configOptOutTracking: false)
                expect(sut.isOptOutTracking).to(beFalse())
            }

            it("config=true, saved=false이면 opt-out") {
                let repository = MemoryKeyValueRepository()
                let sut = OptOutManager(keyValueRepository: repository, configOptOutTracking: true)
                expect(sut.isOptOutTracking).to(beTrue())
                expect(repository.getString(key: "opt_out_tracking")).to(equal("true"))
            }

            it("config=false, saved=true이면 opt-out") {
                let repository = MemoryKeyValueRepository()
                repository.putString(key: "opt_out_tracking", value: "true")
                let sut = OptOutManager(keyValueRepository: repository, configOptOutTracking: false)
                expect(sut.isOptOutTracking).to(beTrue())
            }

            it("config=true, saved=true이면 opt-out") {
                let repository = MemoryKeyValueRepository()
                repository.putString(key: "opt_out_tracking", value: "true")
                let sut = OptOutManager(keyValueRepository: repository, configOptOutTracking: true)
                expect(sut.isOptOutTracking).to(beTrue())
            }
        }

        describe("setOptOutTracking") {
            it("false에서 true로 변경하면 persistence") {
                let repository = MemoryKeyValueRepository()
                let sut = OptOutManager(keyValueRepository: repository, configOptOutTracking: false)

                sut.setOptOutTracking(optOut: true)

                expect(sut.isOptOutTracking).to(beTrue())
                expect(repository.getString(key: "opt_out_tracking")).to(equal("true"))
            }

            it("true에서 false로 변경하면 persistence") {
                let repository = MemoryKeyValueRepository()
                let sut = OptOutManager(keyValueRepository: repository, configOptOutTracking: true)

                sut.setOptOutTracking(optOut: false)

                expect(sut.isOptOutTracking).to(beFalse())
                expect(repository.getString(key: "opt_out_tracking")).to(equal("false"))
            }

            it("동일 값이면 변경 없음") {
                let repository = MemoryKeyValueRepository()
                let sut = OptOutManager(keyValueRepository: repository, configOptOutTracking: true)

                sut.setOptOutTracking(optOut: true)

                expect(sut.isOptOutTracking).to(beTrue())
            }
        }
    }
}
