import Foundation
import UserNotifications

enum NotificationImageHandler {
    static func handlePushImage(notificationData: NotificationData, completion: @escaping (UNNotificationAttachment?) -> Void) {
        Log.info("handle push image action")
        downloadImage(data: notificationData) { imageLocalPath in
            guard let url = imageLocalPath else {
                completion(nil)
                return
            }
            do {
                let attachment = try UNNotificationAttachment(identifier: "image", url: url, options: nil)
                completion(attachment)
            } catch {
                Log.info("Failed to create notification attachment: \(error)")
                completion(nil)
            }
        }
    }

    private static func downloadImage(data: NotificationData, completion: @escaping (URL?) -> Void) {
        guard let imageUrl = data.imageUrl,
              !imageUrl.isEmpty else {
            Log.info("Image URL is empty")
            completion(nil)
            return
        }

        if let url = URL(string: imageUrl) {
            let sink = UncheckedSendableBox(completion)
            URLSession.shared.downloadTask(with: url) { (location, response, error) in
                guard let response = response,
                      let location = location,
                      error == nil else {
                    Log.info("Push Image download error: \(error?.localizedDescription ?? "")")
                    sink.value(nil)
                    return
                }

                guard let mimeType = response.mimeType,
                      MimeType.isSupportedPushNotificationImage(mimeType: mimeType),
                      let fileExtension = MimeType.preferredFileExtension(mimeType: mimeType)
                else {
                    Log.info("Image type check error: \(response.mimeType ?? "")")
                    sink.value(nil)
                    return
                }

                do {
                    let destinationURL = location.appendingPathExtension(fileExtension)
                    try FileManager.default.moveItem(at: location, to: destinationURL)
                    sink.value(destinationURL)
                } catch {
                    Log.info("Image rename error")
                    sink.value(nil)
                }
            }.resume()
        } else {
            Log.info("Image URL is not a valid URL: \(imageUrl)")
            completion(nil)
        }
    }
}
