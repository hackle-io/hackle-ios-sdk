//
//  UrlHandler.swift
//  Hackle
//
//  Created by yong on 2023/07/18.
//

import Foundation
import UIKit

protocol UrlHandler: Sendable {
    @MainActor func open(url: URL)
}

enum UrlSchemes {
    static func isHttp(_ scheme: String) -> Bool {
        return scheme == "http" || scheme == "https"
    }
}
