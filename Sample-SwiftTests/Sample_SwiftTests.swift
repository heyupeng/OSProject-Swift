//
//  Sample_SwiftTests.swift
//  Sample-SwiftTests
//
//  Created by Peng on 2021/6/9.
//

import XCTest
@testable import Sample_Swift

class Sample_SwiftTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testNumberTypeConverted() {
        var a: Int32 = 0x01000010
        print("a = \(a.debugDescription)")
        
        let ptr = withUnsafePointer(to: &a) { $0 }
        let int16_ptr = ptr.withMemoryRebound(to: Int16.self, capacity: 2) { $0 }
        let b = int16_ptr[0]
        let c = int16_ptr[1]
//        print(" [0] = \(b.debugDescription), [1] = \(c.debugDescription)")
        
        // Int32 to Int16
        let cmps = a.rebound(to: Int16.self)
        print(" [0] = \(cmps[0].debugDescription), [1] = \(cmps[1].debugDescription)")
        assert(cmps[0] == 0x0010 && cmps[1] == 0x0100, "\(cmps[0]) != \(a & 0xffff) || \(cmps[1]) != \(a >> 32 & 0xffff)")
        
        // Int16 to Int32
        let cmp2 = b.rebound(to: Int32.self)
        print(cmp2[0].debugDescription)
        assert(b == cmp2[0], "\(b) != \(cmp2[0])")
    }

    func testUnicode() {
        /*****
         * 汉字编码 0xe2ba80 - 0xe9bfc0
         */
        let st = 0xe00a80 // e2ba80
        let ed = 0xe1ffc0 // e9bfc0
        var flag: Bool = false
        print(st.hexadecimalData)
        for value in st..<(ed+1) {
//            if (value >> 4 & 0xf) < 8 {continue}
            let vdata = value.hexadecimalData
            let s = String(data: vdata, encoding: .utf8)
            if s == nil {
                if flag == true {
                    flag = false
                    print("\n\(value.hexadecimal)")
                }
                continue
            }
            if flag == false {
                flag = true
                print("\(value.hexadecimal)")
            }
            print("\(s!)", terminator: " ")
        }
    }
}

