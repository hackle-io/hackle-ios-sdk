import Foundation
@testable import Hackle

class MockContainer: Container {
    var containerId: Int64
    var bucketId: Int64
    var groups: [ContainerGroup]
}
