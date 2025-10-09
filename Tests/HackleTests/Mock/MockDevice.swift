import Foundation
@testable import Hackle

class MockDevice : Device {

    var id: String
    var isIdCreated: Bool
    var properties: [String: Any]
    
    init(id: String, isIdCreated: Bool, properties: [String: Any]) {
        self.id = id
        self.isIdCreated = isIdCreated
        self.properties = properties
    }
}
