//
//  HackleResources.swift
//  Hackle
//
//  Created by yong on 2023/03/30.
//

import Foundation

public final class HackleResources {
    public static let bundle: Bundle = {
        let candidates = [
            Bundle.main.resourceURL,
            Bundle(for: HackleResources.self).resourceURL
        ]

        let bundleName = "Hackle_Hackle"

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }

        return Bundle(for: HackleResources.self)
    }()
}
