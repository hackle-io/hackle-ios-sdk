import Foundation
import Mockery
@testable import Hackle

class MockContainerGroup: Mock, ContainerGroup {
    var id: Int64
    var experiments: [Int64]
    
    init(id: Int64, experiments: [Int64]) {
        self.id = id
        self.experiments = experiments
        super.init()
    }
}
