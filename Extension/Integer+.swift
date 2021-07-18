//
//  Data+Extension.swift
//  Sample-Swift
//
//  Created by Peng on 2022/8/6.
//

import Foundation

// MARK: Convert to Int
protocol IntegerConvertible {
    /// Convert to a  value of given type comfoms ```BinaryInteger```.
    /// - This is a custom api.
    /// - Parameter type: type of value return.
    /// - Returns: A given type value
    func toInteger<T>(to type: T.Type) -> T where T : BinaryInteger
    
    /// Convert this data to a  ``UInt8`` type value.
    /// - This is a custom api.
    func toUInt8() -> UInt8
    
    /// Convert this data to a  ``UInt16`` type value.
    /// - This is a custom api.
    func toUInt16() -> UInt16
}

extension Data: IntegerConvertible {
    /// Convert to a  value of given type comfoms ```BinaryInteger```.
    /// - This is a custom api.
    /// - Parameter type: type of value return. Default is ``Int``.self
    /// - Returns: A given type value
    func toInteger<T>(to type: T.Type = Int.self) -> T where T : BinaryInteger {
        let value = Swift.withUnsafeBytes(of: self) { rawBufferPointer -> T in
            let bufferPtr = rawBufferPointer.bindMemory(to: type)
            return T(bufferPtr[0])
        }
        return value
    }
    
    func toUInt8() -> UInt8 {
        return toInteger(to: UInt8.self)
    }
    
    func toUInt16() -> UInt16 {
        return toInteger(to: UInt16.self)
    }
}

extension BinaryInteger {
    /// Creates a new value from the given data.
    ///
    ///     let x = Int(<0x4c00>)
    ///     // x == 76
    @available(*, unavailable, renamed: "data.toInteger")
    init(_ data: Data) {
        let value = withUnsafeBytes(of: data) { rawBufferPointer -> Self in
            let bufferPtr = rawBufferPointer.bindMemory(to: Self.self)
            return Self(bufferPtr[0])
        }
        self = value
    }
    
    /// The data of this value.
    ///
    ///     let x: Int = 76
    ///     let data = x.data
    ///     // <4c00 0000>
    var data: Data {
        var value = self
        let data = withUnsafeBytes(of: &value) { bptr in
            Data(bptr.map{$0})
        }
        return data
    }
    
    /// The data type of  hexadecimal of this value.
    ///
    ///     let x: UInt = 76 // 0x4c
    ///     let data = x.hexadecimalData
    ///     // <4c>
    ///     let y: UInt = 0xe2bac0
    ///     print(y.hexadecimalData)
    ///     // <e2bac0>
    var hexadecimalData: Data {
        var value = self
        let data = withUnsafeBytes(of: &value) { bptr in
            bptr.reversed().reduce(into: Data()) { partialResult, byte in
                if byte == 0 && partialResult.count == 0 {return }
                partialResult.append(contentsOf: [byte])
                return;
            }
        }
        if data.count == 0 { return Data([UInt8(0)])}
        return data
    }
}

extension BinaryInteger {
    /// Converts to given integer type
    ///
    /// For example
    ///
    ///     // Int32 to Int16
    ///     let num32 = Int32(0x01000010)
    ///     let cmps32 = num32.rebound(to: Int16.self)
    ///     // [16, 256]
    ///
    ///     // Int16 to Int32
    ///     let num16 = Int16(0x0100)
    ///     let cmps16 = num16.rebound(to: Int32.self)
    ///     // [256]
    func rebound<T>(to type: T.Type) -> [T] where T: BinaryInteger {
        let size0 = MemoryLayout.size(ofValue: self)
        let size1 = MemoryLayout<T>.size
        let count = size0 / size1
        guard count > 1 else {
            return [T(self)]
        }
        var value = self
        let ptr = withUnsafePointer(to: &value) { $0 }
        let rptr = ptr.withMemoryRebound(to: type, capacity: count) { $0 }
        var components: [T] = []
        for idx in 0..<count {
            components.append(rptr[idx])
        }
        return components
    }
}

extension BinaryInteger where Self: CVarArg {
    public var hexadecimal: String {
        let size = MemoryLayout.size(ofValue: self)
        return String(format: "%0\(size*2)x", self)
    }
    
    public var debugDescription: String {
        return "\(self)(0x\(self.hexadecimal), \(type(of: self)))"
    }
}
