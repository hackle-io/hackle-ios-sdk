//
//  HttpHeaders.swift
//  Hackle
//
//  Created by yong on 2023/10/01.
//

import Foundation

enum HttpHeader: String {
    case ifModifiedSince = "If-Modified-Since"
    case lastModified = "Last-Modified"
}

extension HttpHeader {
    func with(value: String) -> [String: String] {
        [rawValue: value]
    }
}
