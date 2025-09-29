import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle


class DefaultContainerResolverSpecs: QuickSpec {
    override func spec() {

        var bucketer: MockBucketer!
        var sut: DefaultContainerResolver!

        beforeEach {
            bucketer = MockBucketer()
            sut = DefaultContainerResolver(bucketer: bucketer)
        }

        it("identifierType 에 해당하는 identifier 가 없는경우 false") {
            // given
            let container = MockContainer()
            let experiment = MockExperiment(identifierType: "custom_type")

            let request = experimentRequest(experiment: experiment)

            // when
            let actual = try sut.isUserInContainerGroup(request: request, container: container)

            // then
            expect(actual) == false
        }

        it("Bucket 없으면 에러") {
            let workspace = MockWorkspace()
            every(workspace.getBucketOrNilMock).returns(nil)

            let container = MockContainer(bucketId: 42)
            let request = experimentRequest(workspace: workspace)

            let actual = expect(try sut.isUserInContainerGroup(request: request, container: container))

            actual.to(throwError(HackleError.error("Bucket[42]")))
        }

        it("Slot 에 할당되지 않았으면 false") {
            // given
            let container = MockContainer()
            let bucket = MockBucket()
            let workspace = MockWorkspace()
            every(workspace.getBucketOrNilMock).returns(bucket)
            let experiment = MockExperiment()
            let user = HackleUser.of(userId: "test_id")

            every(bucketer.bucketingMock).returns(nil)

            let request = experimentRequest(workspace: workspace, user: user, experiment: experiment)

            // when
            let actual = try sut.isUserInContainerGroup(request: request, container: container)

            // then
            expect(actual) == false
        }

        it("Slot 에 할당 되었지만 입력받은 Container 에 해당하는 Group 이 없는 경우 nil") {
            // given
            let experiment = MockExperiment()
            let user = HackleUser.of(userId: "test_id")

            let bucket = MockBucket()
            let slot = MockSlot(variationId: 99)
            every(bucketer.bucketingMock).returns(slot)

            let workspace = MockWorkspace()
            every(workspace.getBucketOrNilMock).returns(bucket)

            let container = MockContainer()
            every(container.getGroupOrNilMock).returns(nil)

            let request = experimentRequest(workspace: workspace, user: user, experiment: experiment)

            // when
            let actual = expect(try sut.isUserInContainerGroup(request: request, container: container))

            // then
            actual.to(throwError(HackleError.error("ContainerGroup[99]")))
        }

        it("할당받은 ContainerGroup 에 입력받은 Experiment 가 없는 경우 false") {
            // given
            let experiment = MockExperiment(id: 320)
            let user = HackleUser.of(userId: "test_id")

            let bucket = MockBucket()
            let slot = MockSlot(variationId: 99)
            every(bucketer.bucketingMock).returns(slot)

            let workspace = MockWorkspace()
            every(workspace.getBucketOrNilMock).returns(bucket)

            let container = MockContainer()
            let containerGroup = MockContainerGroup(experiments: [321])
            every(container.getGroupOrNilMock).returns(containerGroup)

            let request = experimentRequest(workspace: workspace, user: user, experiment: experiment)

            // when
            let actual = try sut.isUserInContainerGroup(request: request, container: container)

            // then
            expect(actual) == false
        }

        it("할당받은 ContainerGroup 에 입력받은 Experiment 가 있는 경우 true") {
            // given
            let experiment = MockExperiment(id: 320)
            let user = HackleUser.of(userId: "test_id")

            let bucket = MockBucket()
            let slot = MockSlot(variationId: 99)
            every(bucketer.bucketingMock).returns(slot)

            let workspace = MockWorkspace()
            every(workspace.getBucketOrNilMock).returns(bucket)

            let container = MockContainer()
            let containerGroup = MockContainerGroup(experiments: [320])
            every(container.getGroupOrNilMock).returns(containerGroup)

            let request = experimentRequest(workspace: workspace, user: user, experiment: experiment)

            // when
            let actual = try sut.isUserInContainerGroup(request: request, container: container)

            // then
            expect(actual) == true
        }
    }
}
