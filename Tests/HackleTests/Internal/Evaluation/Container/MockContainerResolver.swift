import Foundation
import Mockery
@testable import Hackle

class MockContainerResolver: Mock, ContainerResolver {

    lazy var isUserInContainerGroupMock = MockFunction(self, isUserInContainerGroup)

    func isUserInContainerGroup(container: Container, bucket: Bucket, experiment: Experiment, user: HackleUser) throws -> Bool {
        call(isUserInContainerGroupMock, args: (container, bucket, experiment, user))
    }
}
