import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultMutualExclusionResolverSpecs: QuickSpec {

    override func spec() {

        var bucketer: MockBucketer!
        var sut: DefaultMutualExclusionResolver!

        let user = HackleUser.of(userId: "test_id")

        beforeEach {
            bucketer = MockBucketer()
            sut = DefaultMutualExclusionResolver(bucketer: bucketer)
        }

        describe("isMutualExclusionGroup") {
            context("container 에 속한 실험이 아닌 경우") {
                it("container에 속하지 않은 실험은 Next Flow로 진행한다") {
                    let workspace = MockWorkspace()
                    let experiment = MockExperiment(containerId: nil)

                    let actual = try sut.isMutualExclusionGroup(workspace: workspace, experiment: experiment, user: user)

                    expect(actual).to(beTrue())
                }
            }

            context("container 에 속한 실험인 경우") {
                it("container에 속해있지만 container 정보를 찾을 수 없을때 Exception 발생") {
                    let workspace = MockWorkspace()
                    let experiment = MockExperiment(containerId: 1)

                    expect(try sut.isMutualExclusionGroup(workspace: workspace, experiment: experiment, user: user))
                            .to(throwError(HackleError.error("container group not exist. containerId[1]")))
                }

                it("container에 속해있지만 container Bucket 정보를 찾을 수 없을때 Exception 발생") {
                    let container = MockContainer(id: 1, bucketId: 1)

                    let workspace = MockWorkspace()
                    every(workspace.getContainerOrNilMock).returns(container)
                    every(workspace.getBucketOrNilMock).returns(nil)

                    let experiment = MockExperiment(containerId: 1)

                    expect(try sut.isMutualExclusionGroup(workspace: workspace, experiment: experiment, user: user))
                            .to(throwError(HackleError.error("container group bucket not exist. bucketId[1")))
                }

                it("bucketing 결과 slot 정보를 가져오지 못한경우 Next Flow 진행시키지 않는다") {
                    let bucket = MockBucket()

                    let container = MockContainer(id: 1, bucketId: 1)

                    let workspace = MockWorkspace()
                    every(workspace.getContainerOrNilMock).returns(container)
                    every(workspace.getBucketOrNilMock).returns(bucket)

                    let experiment = MockExperiment(containerId: 1)
                    every(bucketer.bucketingMock).returns(nil)

                    let actual = try sut.isMutualExclusionGroup(workspace: workspace, experiment: experiment, user: user)

                    expect(actual).to(beFalse())
                }

                it("bucketing 결과에 해당하는 container group 정보를 못찾는 경우 Next Flow 진행시키지 않는다") {
                    let slot = MockSlot(variationId: 99)

                    let bucket = MockBucket()

                    let container = MockContainer(id: 1, bucketId: 1)
                    every(container.mockFindGroupOrNil).returns(nil)

                    let workspace = MockWorkspace()
                    every(workspace.getContainerOrNilMock).returns(container)
                    every(workspace.getBucketOrNilMock).returns(bucket)

                    let experiment = MockExperiment(containerId: 1)
                    every(bucketer.bucketingMock).returns(slot)

                    let actual = try sut.isMutualExclusionGroup(workspace: workspace, experiment: experiment, user: user)

                    expect(actual).to(beFalse())
                }

                it("실험이 bucketing 결과에 해당하지 않으면 Next Flow를 진행시키지 않는다") {
                    let experimentId: Int64 = 22
                    let slot = MockSlot(variationId: 99)
                    let bucket = MockBucket()

                    let containerGroup = MockContainerGroup(id: 88, experiments: [experimentId])

                    let container = MockContainer(id: 1, bucketId: 1)
                    every(container.mockFindGroupOrNil).returns(containerGroup)

                    let workspace = MockWorkspace()
                    every(workspace.getContainerOrNilMock).returns(container)
                    every(workspace.getBucketOrNilMock).returns(bucket)

                    let experiment = MockExperiment(id: experimentId, containerId: 1)
                    every(bucketer.bucketingMock).returns(slot)

                    let actual = try sut.isMutualExclusionGroup(workspace: workspace, experiment: experiment, user: user)

                    expect(actual).to(beFalse())
                }

                it("실험이 bucketing 결과에 해당하면 Next Flow를 진행한다 ") {
                    let experimentId: Int64 = 22
                    let slot = MockSlot(variationId: 99)
                    let bucket = MockBucket()

                    let containerGroup = MockContainerGroup(id: 99, experiments: [experimentId])

                    let container = MockContainer(id: 1, bucketId: 1)
                    every(container.mockFindGroupOrNil).returns(containerGroup)

                    let workspace = MockWorkspace()
                    every(workspace.getContainerOrNilMock).returns(container)
                    every(workspace.getBucketOrNilMock).returns(bucket)

                    let experiment = MockExperiment(id: experimentId, containerId: 1)
                    every(bucketer.bucketingMock).returns(slot)

                    let actual = try sut.isMutualExclusionGroup(workspace: workspace, experiment: experiment, user: user)

                    expect(actual).to(beTrue())
                }

            }
        }
    }
}
