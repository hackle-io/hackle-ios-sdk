import Foundation
import UserNotifications
import MobileCoreServices

extension UNNotificationRequest {
    var attachment: UNNotificationAttachment? {
        guard let data = NotificationData.from(data: content.userInfo),
              let imageUrlString = data.imageUrl,
              let imageUrl = URL(string: imageUrlString),
              let imageData = try? Data(contentsOf: imageUrl) else {
            return nil
        }
        return try? UNNotificationAttachment(
            identifier: imageUrl.lastPathComponent,
            data: imageData,
            options: nil
        )
    }
}

fileprivate extension UNNotificationAttachment {
    convenience init(identifier: String, data: Data, options: [NSObject: AnyObject]?) throws {
        let fileManager = FileManager.default
        let tempDirName = ProcessInfo.processInfo.globallyUniqueString
        let tempDirUrl = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(tempDirName, isDirectory: true)
        try fileManager.createDirectory(at: tempDirUrl, withIntermediateDirectories: true, attributes: nil)
        let fileURL = tempDirUrl.appendingPathComponent(identifier)
        try data.write(to: fileURL)
        try self.init(identifier: identifier, url: fileURL, options: options)
    }
}
