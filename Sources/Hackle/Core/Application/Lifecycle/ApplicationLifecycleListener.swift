//
//  ApplicationLifecycleListener.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/2/25.
//

import Foundation
import UIKit

protocol ApplicationLifecycleListener {
    func onForeground(_ topViewController: UIViewController?, timestamp: Date, isFromBackground: Bool)
    func onBackground(_ topViewController: UIViewController?, timestamp: Date)
}
