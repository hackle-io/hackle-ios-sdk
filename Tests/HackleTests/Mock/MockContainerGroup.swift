import Foundation
@testable import Hackle

class MockContainerGroup: ContainerGroup {
    var containerGroupId: Int64
    var experiments: [Int64]
}
