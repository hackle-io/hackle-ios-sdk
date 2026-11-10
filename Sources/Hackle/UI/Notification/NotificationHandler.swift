import Foundation
import UIKit
import UserNotifications

class NotificationHandler: @unchecked Sendable {
    static let shared = NotificationHandler(
        dispatchQueue: DispatchQueue(
            label: "io.hackle.NotificationHandler",
            qos: .utility
        )
    )

    private var receiver: NotificationDataReceiver
    private let deferPushLinkUntilInitialized: Bool
    let storage = PendingUrlStorage()
    @MainActor private var urlDispatcher: HackleUrlDispatcher?

    init(dispatchQueue: DispatchQueue) {
        self.receiver = DefaultNotificationDataReceiver(
            dispatchQueue: dispatchQueue,
            repository: DefaultNotificationRepository(sharedDatabase: SharedDatabase.shared)
        )
        self.deferPushLinkUntilInitialized = Bundle.main.hackleInfoBool(forKey: "HackleDeferPushLinkUntilInitialized")
    }

    func setNotificationDataReceiver(receiver: NotificationDataReceiver) {
        self.receiver = receiver
    }

    @MainActor func setUrlDispatcher(_ urlDispatcher: HackleUrlDispatcher) {
        self.urlDispatcher = urlDispatcher
        if let url = storage.drain() {
            urlDispatcher.open(url: url, channel: .push)
        }
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

            guard let url = URL(string: link), url.scheme != nil else {
                Log.info("Landing url is not a valid URL: \(link)")
                return
            }

            Task { @MainActor in
                if let dispatcher = self.urlDispatcher {
                    // 1. 초기화 후
                    //   - dispatcher가 delegate 또는 기본 핸들러로 넘긴다.
                    dispatcher.open(url: url, channel: .push)
                } else {
                    // 2. 초기화 전
                    if self.deferPushLinkUntilInitialized {
                        // 2-1. HackleDeferPushLinkUntilInitialized가 YES: 보관
                        //    - 초기화될 때 setUrlDispatcher가 꺼내 1번과 같은 경로로 처리한다.
                        self.storage.store(url: url)
                    } else {
                        // 2-2. HackleDeferPushLinkUntilInitialized가 없음: 즉시 열기
                        //    - 초기화 전이라 HackleConfig와 HackleDelegate는 적용되지 않는다.
                        ApplicationUrlHandler.shared.open(url: url, channel: .push)
                    }
                }
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
