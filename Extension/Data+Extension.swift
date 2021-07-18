//
//  Data+Extension.swift
//  Sample-Swift
//
//  Created by Peng on 2022/8/6.
//

import Foundation

extension Data {
    init(hexString hex: String) {
        self.init()
        var startIndex = hex.startIndex
        while startIndex != hex.endIndex {
            let e = hex.index(startIndex, offsetBy: 2)
            let byteStr = String(hex[startIndex..<e])
            let byteValue = UInt8(strtol(byteStr, nil, 16))
            self.append(byteValue)
            startIndex = e
        }
    }
    
    var hexString: String {
        let data = self
        return data.reduce("") { result, byte in
            result + String(format: "%02x", byte)
        }
    }
    
    var reversedHexString: String {
        var array: [UInt8] = []
        
        withUnsafeBytes { array.append(contentsOf: $0) }
        
        return array.reversed().reduce("") { (result, byte) -> String in
            result + String(format: "%02x", byte)
        }
    }
}

// MARK: Encode Data to String
extension Data {
    func encodedString(encoding: String.Encoding = .utf8) -> String? {
        return String(data: self, encoding: encoding)
    }
    
    var utf8: String? {
        return String(data: self, encoding: .utf8)
    }
    
    var ascii: String? {
        encodedString(encoding: .ascii)
    }
}
