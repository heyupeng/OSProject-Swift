import UIKit
import MachO
var greeting = "Hello, playground"

var text = "我"
var data = text.data(using: .utf8)

var s = data?.reduce("", { partialResult, byte in
    partialResult + String(format: "%0x", byte)
})

var cs = text.data(using: .unicode)?.reduce("", { partialResult, byte in
    partialResult + String(format: "%0x", byte)
})

func hexadecimal(_ value: Int) -> String {
    let size = MemoryLayout.size(ofValue: value)
    return String(format: "%0\(size)x", value)
}
hexadecimal(1000)

var str = "111"
var s2: UnsafeMutablePointer<CChar>?
var p = UnsafeMutablePointer(s2)
var i = 16
var base = OpaquePointer(bitPattern: i)

//var v = strtod_l(str, p, base)
