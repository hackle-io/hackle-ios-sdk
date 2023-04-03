//
//  HackleResources.swift
//  Hackle
//
//  Created by yong on 2023/03/30.
//

import Foundation

public final class HackleInternalResources {
    public static let bundle: Bundle = {
        let bundleName = "Hackle_Hackle"

        let candidates = [
            Bundle.main.resourceURL,
            Bundle(for: HackleInternalResources.self).resourceURL,
            Bundle.main.bundleURL,
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }

        return Bundle(for: HackleInternalResources.self)
    }()
}
