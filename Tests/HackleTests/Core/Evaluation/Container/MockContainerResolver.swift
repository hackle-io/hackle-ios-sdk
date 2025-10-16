import Foundation
import MockingKit
@testable import Hackle

class MockContainerResolver: Mock, ContainerResolver {

    lazy var isUserInContainerGroupMock = MockFunction(self, isUserInContainerGroup)

    func isUserInContainerGroup(request: ExperimentRequest, container: Container) throws -> Bool {
        call(isUserInContainerGroupMock, args: (request, container))
    }
}
