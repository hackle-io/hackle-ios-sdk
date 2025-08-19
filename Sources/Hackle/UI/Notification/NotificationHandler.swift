import Foundation
import UIKit
import UserNotifications

class NotificationHandler {
    static let shared = NotificationHandler(
        dispatchQueue: DispatchQueue(
            label: "io.hackle.NotificationHandler",
            qos: .utility
        )
    )

    private var receiver: NotificationDataReceiver

    init(dispatchQueue: DispatchQueue) {
        receiver = DefaultNotificationDataReceiver(
            dispatchQueue: dispatchQueue,
            repository: DefaultNotificationRepository(
                sharedDatabase: DatabaseHelper.getSharedDatabase()
            )
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
        guard let imageUrl = notificationData.imageUrl,
              !imageUrl.isEmpty,
              let url = URL(string: imageUrl) else {
            Log.info("Image URL is not a valid")
            completion(nil)
            return
        }
        
        url.download(completion: completion)
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
                url.open()
            } else {
                Log.info("Landing url is not a valid URL: \(link)")
            }
        }
    }
}

extension URL {
    fileprivate func open() {
        guard let scheme = self.scheme else {
            return
        }
        
        if (isHttpScheme(scheme) && isContinueUserActivitySupported()) {
            let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
            userActivity.webpageURL = self
            
            // NOTE: RN/Flutter에서 application State가 inactive일 때 userActivity를 처리하면 RN으로 링크가 전달되지 않음
            //  NotificationCenter에서 UIApplication.didBecomeActiveNotification을 구독하고 active 된 후에 처리
            switch UIUtils.application?.applicationState {
            case .active, .background:
                continueUserActivity(userActivity: userActivity)
            default:
                var observer: NSObjectProtocol?
                observer = NotificationCenter.default.addObserver(
                    forName: UIApplication.didBecomeActiveNotification,
                    object: nil,
                    queue: .main
                ) { [observer] _ in
                    continueUserActivity(userActivity: userActivity)
                    if let obs = observer {
                        NotificationCenter.default.removeObserver(obs)
                    }
                }
            }
        } else {
            openUrl()
        }
    }
    
    fileprivate func download(completion: @escaping (UNNotificationAttachment?) -> Void) {
        let task = URLSession.shared.downloadTask(with: self) { (location, response, error) in
            if let error = error {
                Log.info("Image download error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let location = location else {
                completion(nil)
                return
            }
            
            do {
                let fileManager = FileManager.default
                let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                let fileExtension = self.pathExtension
                let destinationURL = cachesDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(fileExtension)
                
                try fileManager.moveItem(at: location, to: destinationURL)
                
                let attachment = try UNNotificationAttachment(identifier: "image", url: destinationURL, options: nil)
                completion(attachment)
                
            } catch {
                Log.info("Attachment creation error: \(error.localizedDescription)")
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    private func isHttpScheme(_ scheme: String) -> Bool {
        return scheme == "http" || scheme == "https"
    }
    
    private func isContinueUserActivitySupported() -> Bool {
        guard let appDelegate = UIUtils.application?.delegate else {
            return false
        }
        let selector = #selector(UIApplicationDelegate.application(_:continue:restorationHandler:))
        return appDelegate.responds(to: selector)
    }
    
    private func continueUserActivity(userActivity: NSUserActivity) {
        let success = UIUtils.application?.delegate?.application?(
            UIUtils.application!,
            continue: userActivity,
            restorationHandler: { _ in }
        )
        Log.debug("Redirected to universal link: \(self.absoluteString) [success=\(success ?? false)]")
        
        if success != true {
            Log.info("Attempt to open URL alternative")
            openUrl()
        }
    }
    
    private func openUrl() {
        UIUtils.application?.open(self, options: [:]) { success in
            Log.debug("Redirected to: \(self.absoluteString) [success=\(success)]")
        }
    }
}
