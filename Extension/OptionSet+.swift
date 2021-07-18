//
//  OptionSet+.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/9.
//

import Foundation

protocol OptionSetComponenents {
    static var allOptions: [Self] { get }
    var components: [Self] { get }
}

extension OptionSetComponenents where Self: OptionSet, Self.RawValue: Comparable {
    var components: [Self] {
        var options: [Self] = []
        for option in Self.allOptions {
            if self.rawValue < option.rawValue { break }
            if !self.contains(option as! Self.Element) { continue }
            options.append(option)
        }
        return options
    }
}
