//
//  UIKitExt.swift
//  Hackle
//
//  Created by yong on 2023/06/12.
//

import Foundation
import UIKit

extension UIViewController {

    /// iOS 10 호환성을 위한 safe area anchor 설정
    func setupSafeAreaAnchors() -> (top: NSLayoutYAxisAnchor, leading: NSLayoutXAxisAnchor, trailing: NSLayoutXAxisAnchor, bottom: NSLayoutYAxisAnchor) {
        if #available(iOS 11.0, *) {
            return (
                top: view.safeAreaLayoutGuide.topAnchor,
                leading: view.safeAreaLayoutGuide.leadingAnchor,
                trailing: view.safeAreaLayoutGuide.trailingAnchor,
                bottom: view.safeAreaLayoutGuide.bottomAnchor
            )
        } else {
            return (
                top: topLayoutGuide.bottomAnchor,
                leading: view.leadingAnchor,
                trailing: view.trailingAnchor,
                bottom: bottomLayoutGuide.topAnchor
            )
        }
    }
}

extension UIColor {

    convenience init?(hex: String, alpha: CGFloat = 1.0) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        let scanner = Scanner(string: hexString)

        if hexString.hasPrefix("#") {
            scanner.scanLocation = 1
        }

        var color: UInt32 = 0
        if scanner.scanHexInt32(&color) {
            let mask = 0x000000FF
            let red = CGFloat(Int(color >> 16) & mask) / 255.0
            let green = CGFloat(Int(color >> 8) & mask) / 255.0
            let blue = CGFloat(Int(color) & mask) / 255.0

            self.init(red: red, green: green, blue: blue, alpha: alpha)
            return
        }
        return nil
    }
}

extension UIButton {

    func onClick(_ action: @escaping () -> ()) {
        @objc final class Listener: NSObject {
            let action: () -> ()

            init(_ action: @escaping () -> ()) {
                self.action = action
            }

            @objc func onClick() {
                action()
            }
        }

        let listener = Listener(action)
        self.addTarget(listener, action: #selector(Listener.onClick), for: .touchUpInside)
        objc_setAssociatedObject(self, UUID().uuidString, listener, .OBJC_ASSOCIATION_RETAIN)
    }
}

extension UIImageView {

    func loadImage(url: String, completion: (() -> Void)? = nil) {
        let cacheKey = NSString(string: url)
        if let cachedImage = ImageCacheManager.shared.object(forKey: cacheKey) {
            self.image = cachedImage
            completion?()
            return
        }

        guard let url = URL(string: url) else {
            Log.error("Invalid url: \(url)")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    Log.error("Failed to load image [\(url)]: \(error)")
                    return
                }

                DispatchQueue.main.async {
                    if let data = data, let image = UIImage(data: data) {
                        ImageCacheManager.shared.setObject(image, forKey: cacheKey)
                        self.image = image
                        completion?()
                    }
                }
            }
            .resume()
    }
}

extension UIResponder {
    var responders: AnySequence<UIResponder> {
        AnySequence { () -> AnyIterator<UIResponder> in
            var responder: UIResponder? = self
            return AnyIterator {
                responder = responder?.next
                return responder
            }
        }
    }
}

extension CGSize {
    var aspectRatio: Double {
        width / height
    }
}
