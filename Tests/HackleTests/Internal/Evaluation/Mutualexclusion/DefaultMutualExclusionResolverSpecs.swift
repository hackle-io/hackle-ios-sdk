import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultMutualExclusionResolverSpecs: QuickSpec {

    override func spec() {

        var bucketer: MockBucketer!
        var sut: DefaultMutualExclusionResolver!

        let identifier = HackleUser.of(userId: "test_id")

        beforeEach {
            bucketer = MockBucketer()
            sut = DefaultMutualExclusionResolver(bucketer: bucketer)
        }

        describe("resolve") {
            context("container 에 속한 실험이 아닌 경우") {
                it("container에 속하지 않은 실험은 Next Flow로 진행한다") {
                    let workspace = MockWorkspace()
                    let experiment = MockExperiment()
                    every(experiment.contianerId).returns(null)

                    let actual = try sut.resolve(workspace: workspace, experiment: experiment, identifier: identifier)

                    expect(actual).to(beTrue())
                }
            }

            context("container 에 속한 실험인 경우") {
                it("container에 속해있지만 container 정보를 찾을 수 없을때 Exception 발생") {
                    let workspace = MockWorkspace()
                    let experiment = MockExperiment()
                    every(experiment.contianerId).returns(1)

                    expect(try sut.resolve(workspace: workspace, experiment: experiment, identifier: identifier))
                            .to(throwError(HackleError.error("container group not exist. containerId[1]")))
                }

                it("container에 속해있지만 container Bucket 정보를 찾을 수 없을때 Exception 발생") {
                    let container = MockContainer()
                    every(container.containerId).returns(1)
                    every(container.bucketId).returns(1)

                    let workspace = MockWorkspace()
                    every(workspace.getContainerOrNil(containerId: 1)).returns(container)
                    every(workspace.getBucketOrNil(bucketId: 1)).returns(null)

                    let experiment = MockExperiment()
                    every(experiment.contianerId).returns(1)

                    expect(try sut.resolve(workspace: workspace, experiment: experiment, identifier: identifier))
                            .to(throwError(HackleError.error("container group bucket not exist. bucketId[1")))
                }

                it("bucketing 결과 slot 정보를 가져오지 못한경우 Next Flow 진행시키지 않는다") {
                    let bucket = MockBucket()

                    let container = MockContainer()
                    every(container.containerId).returns(1)
                    every(container.bucketId).returns(1)

                    let workspace = MockWorkspace()
                    every(workspace.getContainerOrNil(containerId: 1)).returns(container)
                    every(workspace.getBucketOrNil(bucketId: 1)).returns(bucket)

                    let experiment = MockExperiment()
                    every(experiment.contianerId).returns(1)
                    every(bucketer.bucketing(bucket, any())).returns(null)
                    every(experiment.identifierType).returns(IdentifierType.id)

                    let actual = try sut.resolve(workspace: workspace, experiment: experiment, identifier: identifier)

                    expect(actual).to(beFalse())
                }

                it("bucketing 결과에 해당하는 container group 정보를 못찾는 경우 Next Flow 진행시키지 않는다") {
                    let slot = MockSlot(variationId: 99)

                    let bucket = MockBucket()

                    let container = MockContainer()
                    every(container.containerId).returns(1)
                    every(container.bucketId).returns(1)
                    every(container.findGroup(containerGroupId: 99)).returns(null)

                    let workspace = MockWorkspace()
                    every(workspace.getContainerOrNil(containerId: 1)).returns(container)
                    every(workspace.getBucketOrNil(bucketId: 1)).returns(bucket)

                    let experiment = MockExperiment()
                    every(experiment.contianerId).returns(1)
                    every(bucketer.bucketing(bucket, any())).returns(slot)
                    every(experiment.identifierType).returns(IdentifierType.id)

                    let actual = try sut.resolve(workspace: workspace, experiment: experiment, identifier: identifier)

                    expect(actual).to(beFalse())
                }

                it("실험이 bucketing 결과에 해당하지 않으면 Next Flow를 진행시키지 않는다") {
                    let experimentId = 22
                    let slot = MockSlot(variationId: 99)
                    let bucket = MockBucket()

                    let containerGroup = MockContainerGroup(88, [experimentId])

                    let container = MockContainer()
                    every(container.containerId).returns(1)
                    every(container.bucketId).returns(1)
                    every(container.findGroup(containerGroupId: 99)).returns(MockContainerGroup())

                    let workspace = MockWorkspace()
                    every(workspace.getContainerOrNil(containerId: 1)).returns(container)
                    every(workspace.getBucketOrNil(bucketId: 1)).returns(bucket)

                    let experiment = MockExperiment(experimentId = experimentId)
                    every(experiment.contianerId).returns(1)
                    every(bucketer.bucketing(bucket, any())).returns(slot)
                    every(experiment.identifierType).returns(IdentifierType.id)

                    let actual = try sut.resolve(workspace: workspace, experiment: experiment, identifier: identifier)

                    expect(actual).to(beFalse())
                }

                it("실험이 bucketing 결과에 해당하면 Next Flow를 진행한다 ") {
                    let experimentId = 22
                    let slot = MockSlot(variationId: 99)
                    let bucket = MockBucket()

                    let containerGroup = MockContainerGroup(99, [experimentId])

                    let container = MockContainer()
                    every(container.containerId).returns(1)
                    every(container.bucketId).returns(1)
                    every(container.findGroup(containerGroupId: 99)).returns(MockContainerGroup())

                    let workspace = MockWorkspace()
                    every(workspace.getContainerOrNil(containerId: 1)).returns(container)
                    every(workspace.getBucketOrNil(bucketId: 1)).returns(bucket)

                    let experiment = MockExperiment(experimentId = experimentId)
                    every(experiment.contianerId).returns(1)
                    every(bucketer.bucketing(bucket, any())).returns(slot)
                    every(experiment.identifierType).returns(IdentifierType.id)

                    let actual = try sut.resolve(workspace: workspace, experiment: experiment, identifier: identifier)

                    expect(actual).to(beTrue())
                }

            }
        }
    }
}
