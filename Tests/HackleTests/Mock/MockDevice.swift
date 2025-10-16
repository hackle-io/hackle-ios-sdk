import Foundation
@testable import Hackle

class MockDevice : Device {

    var id: String
    var properties: [String: Any]
    
    init(id: String, properties: [String: Any]) {
        self.id = id
        self.properties = properties
    }
}
