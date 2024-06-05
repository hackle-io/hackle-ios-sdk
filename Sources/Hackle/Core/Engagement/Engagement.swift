import Foundation

struct Engagement: Equatable {
    let screen: Screen
    let duration: TimeInterval
}

extension Engagement: CustomStringConvertible {
    public var description: String {
        "Engagement(screen: \(screen), duration: \(duration))"
    }
}
