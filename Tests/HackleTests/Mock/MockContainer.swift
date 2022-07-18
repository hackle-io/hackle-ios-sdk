import Foundation
import Mockery
@testable import Hackle

class MockContainer: Mock, Container {
    var id: Int64
    var bucketId: Int64
    var groups: [ContainerGroup]
    
    init(
        id: Int64 = 1,
        bucketId: Int64 = 1,
        groups: [ContainerGroup] = []
    ) {
        self.id = id
        self.bucketId = bucketId
        self.groups = groups
        super.init()
    }

    lazy var mockFindGroupOrNil = MockFunction(self, findGroupOrNil)

    func findGroupOrNil(containerGroupId: Int64) -> ContainerGroup? {
        call(mockFindGroupOrNil, args: containerGroupId)
    }
}
