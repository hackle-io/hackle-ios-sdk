//
//  MimeTypeResolver.swift
//  Hackle
//
//  Created by sungwoo.yeo on 8/21/25.
//

import Foundation
import UniformTypeIdentifiers
import MobileCoreServices

enum MimeTypeResolver {
    /// MimeType의 파일 확장자를 리턴합니다.
    /// - Parameter mimeType: mimeType
    /// - Returns: 확장자
    static func preferredFileExtension(mimeType: String) -> String? {
        if #available(iOS 14.0, *) {
            guard let type = UTType(mimeType: mimeType) else {
                return nil
            }
            return type.preferredFilenameExtension
        } else {
            // NOTE: deprecated on iOS 15
            let cfMimeType = mimeType as CFString
            guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, cfMimeType, nil)?.takeRetainedValue() else {
                return nil
            }
            guard let fileExtension = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension)?.takeRetainedValue() else {
                return nil
            }
            return fileExtension as String
        }
    }
    
    /// MimeType이 푸시 이미지가 지원하는 타입인지 확인합니다.
    ///
    /// 푸시는 jpeg, png, gif 이미지만 지원합니다.
    /// - Parameter mimeType: mimeType
    /// - Returns: 푸시 이미지 여부
    static func isSupportedPushNotificationImage(mimeType: String) -> Bool {
        if #available(iOS 14.0, *) {
            guard let type = UTType(mimeType: mimeType) else {
                return false
            }
            return type.conforms(to: .jpeg) || type.conforms(to: .png) || type.conforms(to: .gif)
        } else {
            guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue() else {
                return false
            }
            return UTTypeConformsTo(uti, kUTTypeJPEG) || UTTypeConformsTo(uti, kUTTypePNG) || UTTypeConformsTo(uti, kUTTypeGIF)
        }
    }
}
