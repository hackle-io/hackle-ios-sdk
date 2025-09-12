//
//  HackleInvocator.swift
//  Hackle
//
//  Created by sungwoo.yeo on 8/12/25.
//

import Foundation

/// Protocol for invoking Hackle SDK operations programmatically.
@objc public protocol HackleInvocator {
    /// Checks if a string can be invoked by this invocator.
    ///
    /// - Parameter string: the string to check
    /// - Returns: true if the string is invocable, false otherwise
    @objc func isInvocableString(string: String) -> Bool
    
    /// Invokes an operation with the given string.
    ///
    /// - Parameter string: the string to invoke
    /// - Returns: the result of the invocation
    @objc func invoke(string: String) -> String
    
    /// Invokes an operation with the given string and completion handler.
    ///
    /// - Parameters:
    ///   - string: the string to invoke
    ///   - completionHandler: callback to be executed when the operation is complete
    @objc func invoke(string: String, completionHandler: (String?) -> Void)
}
