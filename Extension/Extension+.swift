//
//  Data+Extension.swift
//  Sample-Swift
//
//  Created by Peng on 2022/8/6.
//

import Foundation

/// Retue true if given value is ``nil`` or ``NSNull``.
/// - This is a custom api.
func isEmpty(_ value: Sendable?) -> Bool {
    if value == nil { return true }
    if value is NSNull { return true }
    return false
}

extension Sendable {
    var isNull: Bool {
        return self is NSNull
    }
}
