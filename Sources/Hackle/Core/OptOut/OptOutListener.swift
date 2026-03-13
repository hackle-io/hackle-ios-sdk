import Foundation

protocol OptOutListener {
    func onOptOutChanged(previous: Bool, current: Bool)
}
