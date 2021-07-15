//
//  String+Extension.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/11.
//

import Foundation

protocol SubstrProtocol {
    func substr(from: Int, to: Int) -> String
    func substr(from: Int) -> String
    func substr(to: Int) -> String
    
    func substr(from fromIndex: String.Index, to toIndex: String.Index) -> String
    func substr(from index: String.Index) -> String
    func substr(to: String.Index) -> String
    
    func substr(with range: Range<String.Index>) -> String
}

extension String: SubstrProtocol {
    
    func substr(from: Int, to: Int) -> String {
        let fromIndex = self.index(Index(utf16Offset: 0, in: self), offsetBy: from)
        let toIndex = self.index(Index(utf16Offset: 0, in: self), offsetBy: to)
        return String(self[fromIndex..<toIndex])
    }
    
    func substr(from index: Int) -> String {
        return self.substr(from: index, to: self.count-1)
    }
    
    func substr(to index: Int) -> String {
        return self.substr(from: 0, to: index)
    }
    
    func substr(from fromIndex: String.Index, to toIndex: String.Index) -> String {
        return String(self[fromIndex..<toIndex])
    }
    
    func substr(from index: String.Index) -> String {
        return String(self[index..<self.endIndex])
    }
    
    func substr(to index: String.Index) -> String {
        return String(self[self.startIndex..<index])
    }
    
    func substr(with range: Range<String.Index>) -> String {
        return String(self[range.lowerBound..<range.upperBound])
    }
}
