//
//  Array+Extension.swift
//  Sample-Swift
//
//  Created by Peng on 2021/5/24.
//

import Foundation

extension Array {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
