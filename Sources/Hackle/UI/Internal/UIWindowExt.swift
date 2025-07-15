//
//  UIWindowExt.swift
//  Hackle
//
//  Created by sungwoo.yeo on 7/15/25.
//

import UIKit

@available(iOS 13.0, *)
extension UIWindow {

    /// 특정 뷰를 새로운 PassthroughWindow에 띄워서 반환하는 static 함수
    /// - Parameters:
    ///   - floatingView: 윈도우에 띄울 뷰
    ///   - level: 윈도우의 레벨 (기본값: .normal + 1)
    /// - Returns: 생성된 PassthroughWindow (씬을 찾지 못하면 nil)
    static func show(floatingView: UIView, level: UIWindow.Level = .normal + 1) -> PassthroughWindow? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return nil
        }
        
        let window = PassthroughWindow(windowScene: windowScene)
        
        let viewController = UIViewController()
        viewController.view.addSubview(floatingView)
        window.rootViewController = viewController
        
        window.windowLevel = level
        window.makeKeyAndVisible()
        
        return window
    }
}
