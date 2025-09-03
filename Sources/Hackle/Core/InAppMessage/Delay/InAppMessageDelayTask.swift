import Foundation

protocol InAppMessageDelayTask {
    var delay: InAppMessageDelay { get }
    func cancel()
}
