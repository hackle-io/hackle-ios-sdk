import Foundation

protocol ScreenListener {
    func onScreenStarted(previousScreen: Screen?, currentScreen: Screen, user: User, timestamp: Date)
    func onScreenEnded(screen: Screen, user: User, timestamp: Date)
}
