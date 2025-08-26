import Foundation

protocol InAppMessageDelayTask {
    var delay: InAppMessageDelay { get }
    var isCompleted: Bool { get }
    func cancel()
}
