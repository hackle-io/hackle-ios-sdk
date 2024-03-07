import Foundation
import UIKit

protocol PushTokenDataSource {
    func getPushToken() -> String?
}
