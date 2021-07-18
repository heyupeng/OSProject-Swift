//
//  CSVParser.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/9.
//

import Foundation

class CSVParser: NSObject {
    private var url: URL!
    
    convenience init(contentsOf url: URL) {
        self.init()
        self.url = url
    }
    
    private(set) var entities: [[String]] = []
    
    func parse() -> Bool {
        do {
            let ch1: UInt8 = 0x22 // (")
            let ch2: UInt8 = 0x2c // (,)
            let LF: UInt8 = 0x0a // (\n)
            let CR: UInt8 = 0x0d // (\r)
            let content = try Data(contentsOf: url)
            
            var row: [String] = []
            var element: Data = Data()
            var ch1Count = 0
            var lastByte: UInt8 = 0
            content.forEach { byte in
                defer {
                    lastByte = byte
                }
                if byte == ch1 {
                    ch1Count = 1 - ch1Count
                    if !(lastByte == ch1 && ch1Count == 1) {
                        return
                    }
                }
                else if byte == ch2, ch1Count == 0 {
                    // Todo:
                    didEndElement(element: element, row: &row)
                    element = Data()
                    return
                }
                else if byte == LF, ch1Count == 0 {
                    // Todo:
                    if lastByte == CR { element.removeLast() }
                    didEndElement(element: element, row: &row)
                    didEndRow(row: row)
                    element = Data()
                    row = []
                    return
                }
                element.append(byte)
            }
        } catch {
            return false
        }
        return true
    }
    
    func didEndElement(element: Data, row: inout [String]) {
        let e = element.utf8 ?? "<Empty>"
        row.append(e)
    }
    
    func didEndRow(row: [String]) {
        entities.append(row)
    }
}
