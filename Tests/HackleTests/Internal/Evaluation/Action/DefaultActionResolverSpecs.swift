import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultActionResolverSpecs: QuickSpec {

    override func spec() {

        var bucketer: MockBucketer!
        var sut: DefaultActionResolver!

        let user = Hackle.user(id: "test_id")

        beforeEach {
            bucketer = MockBucketer()
            sut = DefaultActionResolver(bucketer: bucketer)
        }

        describe("resolveOrNil") {
            context("variation type 인 경우") {
                it("variationId에 해당하는 Variation 을 가져온다") {
                    // given
                    let action = ActionEntity(type: .variation, variationId: 1, bucketId: nil)

                    let variation = MockVariation()
                    let experiment = MockRunningExperiment(defaultRule: action)
                    every(experiment.getVariationByIdOrNilMock).returns(variation)

                    // when
                    let actual = try sut.resolveOrNil(action: action, workspace: MockWorkspace(), experiment: experiment, user: user)

                    // then
                    expect(actual).to(beIdenticalTo(variation))
                }


                it("variationId 가 없는 경우 예외 발생") {
                    // given
                    let action = ActionEntity(type: .variation, variationId: nil, bucketId: nil)

                    let experiment = MockRunningExperiment(id: 320, defaultRule: action)

                    // when
                    expect(try sut.resolveOrNil(action: action, workspace: MockWorkspace(), experiment: experiment, user: user))
                        .to(throwError(HackleError.error("action variation[320]")))
                }

                it("experiment에 variationId에 해당하는 Variation이 없으면 예외 발생") {
                    // given
                    let action = ActionEntity(type: .variation, variationId: 42, bucketId: nil)

                    let experiment = MockRunningExperiment(id: 320, defaultRule: action)
                    every(experiment.getVariationByIdOrNilMock).returns(nil)

                    // when
                    expect(try sut.resolveOrNil(action: action, workspace: MockWorkspace(), experiment: experiment, user: user))
                        .to(throwError(HackleError.error("variation[42]")))
                }
            }

            context("bucket type 인 경우") {
                it("bucketId 가 없으면 예외 발생") {
                    // given
                    let action = ActionEntity(type: .bucket, variationId: nil, bucketId: nil)
                    let experiment = MockRunningExperiment(id: 42, defaultRule: action)

                    // when
                    expect(try sut.resolveOrNil(action: action, workspace: MockWorkspace(), experiment: experiment, user: user))
                        .to(throwError(HackleError.error("action bucket[42]")))
                }

                it("bucket이 없는 경우 예외 발생") {
                    // given
                    let action = ActionEntity(type: .bucket, variationId: nil, bucketId: 320)
                    let experiment = MockRunningExperiment(id: 42, defaultRule: action)
                    let workspace = MockWorkspace()
                    every(workspace.getBucketOrNilMock).returns(nil)

                    // when
                    expect(try sut.resolveOrNil(action: action, workspace: workspace, experiment: experiment, user: user))
                        .to(throwError(HackleError.error("bucket[320]")))
                }

                it("슬롯에 할당되지 않았으면 nil리턴") {
                    // given
                    let action = ActionEntity(type: .bucket, variationId: nil, bucketId: 320)
                    let experiment = MockRunningExperiment(id: 42, defaultRule: action)
                    let workspace = MockWorkspace()
                    let bucket = MockBucket()
                    every(workspace.getBucketOrNilMock).returns(bucket)

                    every(bucketer.bucketingMock).returns(nil)

                    // when
                    let actual = try sut.resolveOrNil(action: action, workspace: workspace, experiment: experiment, user: user)

                    // then
                    expect(actual).to(beNil())
                }

                it("슬롯에 할당되었지만 슬롯의 variationId에 해당하는 Variation이 Experiment에 없으면 nil리턴") {
                    // given
                    let action = ActionEntity(type: .bucket, variationId: nil, bucketId: 320)
                    let workspace = MockWorkspace()
                    let bucket = MockBucket()
                    every(workspace.getBucketOrNilMock).returns(bucket)

                    let slot = MockSlot(variationId: 99)
                    every(bucketer.bucketingMock).returns(slot)

                    let experiment = MockRunningExperiment(id: 42, defaultRule: action)
                    every(experiment.getVariationByIdOrNilMock).returns(nil)

                    // when
                    let actual = try sut.resolveOrNil(action: action, workspace: workspace, experiment: experiment, user: user)

                    // then
                    expect(actual).to(beNil())
                }

                it("버켓팅을 통해 할당된 Variation 리턴") {
                    // given
                    let action = ActionEntity(type: .bucket, variationId: nil, bucketId: 320)
                    let workspace = MockWorkspace()
                    let bucket = MockBucket()
                    every(workspace.getBucketOrNilMock).returns(bucket)

                    let slot = MockSlot(variationId: 99)
                    every(bucketer.bucketingMock).returns(slot)

                    let variation = MockVariation()
                    let experiment = MockRunningExperiment(id: 42, defaultRule: action)
                    every(experiment.getVariationByIdOrNilMock).returns(variation)

                    // when
                    let actual = try sut.resolveOrNil(action: action, workspace: workspace, experiment: experiment, user: user)

                    // then
                    expect(actual).to(beIdenticalTo(variation))
                }
            }
        }
    }
}