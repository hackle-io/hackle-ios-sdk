//
//  UrlHandler.swift
//  Hackle
//
//  Created by yong on 2023/07/18.
//

import Foundation


protocol UrlHandler {
    func open(url: URL)
}

class ApplicationUrlHandler: UrlHandler {
    func open(url: URL) {
        UIUtils.application.open(url)
    }
}
