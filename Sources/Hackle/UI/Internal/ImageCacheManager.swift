//
//  ImageCacheManager.swift
//  Hackle
//
//  Created by yong on 2023/06/28.
//

import Foundation
import UIKit


final class ImageCacheManager: @unchecked Sendable {
    static let shared = ImageCacheManager()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
    }

    func object(forKey key: String) -> UIImage? {
        cache.object(forKey: NSString(string: key))
    }

    func setObject(_ obj: UIImage, forKey key: String) {
        cache.setObject(obj, forKey: NSString(string: key))
    }
}
