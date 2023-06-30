//
//  ImageCacheManager.swift
//  Hackle
//
//  Created by yong on 2023/06/28.
//

import Foundation
import UIKit


class ImageCacheManager {
    static let shared = NSCache<NSString, UIImage>()

    private init() {
    }
}
