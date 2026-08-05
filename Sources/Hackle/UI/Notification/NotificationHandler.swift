import Foundation
import UIKit
import UserNotifications

class NotificationHandler: @unchecked Sendable {
    static let shared = NotificationHandler(
        dispatchQueue: DispatchQueue(
            label: "io.hackle.NotificationHandler",
            qos: .utility
        ),
        urlHandler: ApplicationUrlHandler()
    )

    private var receiver: NotificationDataReceiver
    private let urlHandler: UrlHandler

    init(dispatchQueue: DispatchQueue, urlHandler: UrlHandler) {
        self.urlHandler = urlHandler
        self.receiver = DefaultNotificationDataReceiver(
            dispatchQueue: dispatchQueue,
            repository: DefaultNotificationRepository(sharedDatabase: SharedDatabase.shared)
        )
    }

    func setNotificationDataReceiver(receiver: NotificationDataReceiver) {
        self.receiver = receiver
    }

    func trackPushClickEvent(notificationData: NotificationData, timestamp: Date = Date()) {
        Log.info("track push click event")
        receiver.onNotificationDataReceived(data: notificationData, timestamp: timestamp)
    }

    func handlePushClickAction(notificationData: NotificationData) {
        Log.info("handle push click action: \(notificationData.actionType.rawValue)")
        trampoline(data: notificationData)
    }

    func handlePushImage(notificationData: NotificationData, completion: @escaping (UNNotificationAttachment?) -> Void) {
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
}

extension NotificationHandler {
    private func trampoline(data: NotificationData) {
        switch (data.clickAction) {
        case .appOpen:
            break;
        case .deepLink:
            guard let link = data.link,
                  !link.isEmpty else {
                Log.info("Landing url is empty.")
                return
            }

            if let url = URL(string: link) {
                Task { @MainActor in
                    urlHandler.open(url: url)
                }
            } else {
                Log.info("Landing url is not a valid URL: \(link)")
            }
        }
    }

    private func downloadImage(data: NotificationData, completion: @escaping (URL?) -> Void) {
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
                    // NOTE: 이미지 저장 된 url을 리턴
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

/// non-Sendable 값을 `@Sendable` 클로저 경계 너머로 손으로 나른다.
/// 값이 정확히 1회 넘겨지고 동시 접근이 없는 경우에만 안전하다.
private final class UncheckedSendableBox<T>: @unchecked Sendable {
    let value: T
    init(_ value: T) { self.value = value }
}
