import Foundation

protocol InAppMessageConfig: InAppMessage, ConfigEntity {
    var status: InAppMessage.Status { get }
    var targetContext: InAppMessage.TargetContext { get }
}
