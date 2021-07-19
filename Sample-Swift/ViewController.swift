//
//  ViewController.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/9.
//

import Cocoa
import Foundation

class ViewController: NSViewController {
    typealias CClosureType =  @convention(c) ()->Void
    typealias ClosureType =  ()->Void
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func testMethodToClosure1() {
        testclosure2pointer2()
        print("testMethodToClosure1 started")
        
        let cls: AnyClass? = object_getClass(self)
        let selector = #selector(objcabc1(a:))
//        var m = class_getInstanceMethod(cls, selector)!
        var m: Method = classMethod(self.classForCoder, selector: selector)!
        
        let type2 = CClosureType.self
        let type3 = ClosureType.self
        let type1 = type(of: self.objcabc1(a:))
        
        let type4 = (@convention(c) (AnyObject, Selector, Int)->Void).self
        let c1 = methodImplementation(m, to: type4)
        c1(self, selector, 12)

        print("testMethodToClosure1 finish")
        
        testInstanceMethodToClosureAboutBitCast()
    }
    
    func testInstanceMethodToClosureAboutBitCast() {
        print("testInstanceMethodToClosureAboutBitCast started")
        
        let cls: AnyClass = self.classForCoder // object_getClass(self)
        let selector = #selector(objcabc1(a:))
        
        let method = class_getInstanceMethod(cls, selector)
        let imp = method_getImplementation(method!)
        
        let type4 = (@convention(c) (AnyObject, Selector, Int, Int)-> Void).self
        let invokefunc = unsafeBitCast(imp, to: type4)
        invokefunc(self, selector, 101, 1000)
        
        print("testInstanceMethodToClosureAboutBitCast finish")
    }
    
    @objc func objcabc() {
        print("[objc method] test converting closure to pointer")
    }
    
    @objc func objcabc1( a: Int) {
        print("[objc method] test converting closure to pointer (\(a))")
    }
    
    func abc() {
        print("[object method] test converting closure to pointer")
    }
    func abcWith1(a: Int) {
        print("[object method] with 1 arg. (\(a))")
    }
    
    func testclosure2pointer1() {
        var closure = self.abcWith1
        let type1 = type(of: closure)
        let type2 = CClosureType.self
        let type3 = ClosureType.self
        
        /* UnsafePointer(&closure) : error (bad access) */
//        var ptr = UnsafePointer(&closure)
        let ptr = withUnsafePointer(to: &closure) { $0 }
        let ptr_p = ptr.pointee
        let raw_ptr = UnsafeRawPointer(ptr)
        let opa_ptr = OpaquePointer(ptr)
        
        /// only ``type1 = type(of: closure)`` ,  ``type3 = ClosureType.self ``, it can be run
        pointer2closure1(opa_ptr, to: type1)?(1)
        pointer2closure2(opa_ptr, to: type1)?(2)
        pointer2closure3(opa_ptr, to: type1)?(3)
    }
    
    func testclosure2pointer2() {
        print("testclosure2pointer2 started")
        var closure = self.abcWith1(a:) // { print("[auto closure] test converting closure to pointer")}
        let type1 = type(of: closure)
        let type2 = ClosureType.self
        
        let opa_ptr = closure2pointer(&closure)
        
        let c1 = pointer2closure1(opa_ptr, to: type1)
        c1?(1)
        let c2 = pointer2closure2(opa_ptr, to: type1)
        c2?(2)
        let c3 = pointer2closure3(opa_ptr, to: type1)
        c3?(3)
        let c4 = pointer2closure4(opa_ptr, to: type1)
        c4(4)
        print("testclosure2pointer2 finish")
    }
}

extension NSObject {
    func closure2pointer<T>(_ closure: inout T) -> OpaquePointer {
//        let ptr = UnsafePointer(&closure)
        let ptr = withUnsafePointer(to: &closure) { $0 }
        let ptr_p = ptr.pointee
        let raw_ptr = UnsafeRawPointer(ptr)
        let opa_ptr = OpaquePointer(ptr)
        
        print("closure size: \(MemoryLayout.size(ofValue: closure))")
        print("        ptr size: \(MemoryLayout.size(ofValue: ptr))")
        print("        ptr.pointee size: \(MemoryLayout.size(ofValue: ptr_p))")
        print("        raw ptr size: \(MemoryLayout.size(ofValue: raw_ptr))")
        print("        opa ptr size: \(MemoryLayout.size(ofValue: opa_ptr))")
        return opa_ptr
    }
    
    func pointer2closure1<T>(_ opaquePtr: OpaquePointer, to type: T.Type) -> T? {
        // way 1
        let ptr = UnsafePointer<T>(opaquePtr)
        let ptr_pte = ptr.pointee
        return ptr_pte
    }
    
    func pointer2closure2<T>(_ opaquePtr: OpaquePointer, to type: T.Type) -> T? {
        // way 2
        let raw_ptr = UnsafeRawPointer(opaquePtr)
        let ptr = raw_ptr.assumingMemoryBound(to: type)
        let ptr_pte = ptr.pointee
        return ptr_pte
    }
    
    func pointer2closure3<T>(_ opaquePtr: OpaquePointer, to type: T.Type) -> T? {
        // way 3
        let raw_ptr = UnsafeRawPointer(opaquePtr)
        let ptr = raw_ptr.withMemoryRebound(to: type, capacity: 1) { $0 }
        let ptr_pte = ptr.pointee
        return ptr_pte
    }
    
    func pointer2closure4<T>(_ opaquePtr: OpaquePointer, to type: T.Type) -> T {
        // copy an opa-ptr. (error EXC_BAD_ACCESS)
        let opa_ptr = opaquePtr
        let b_ptr = withUnsafeBytes(of: opa_ptr) { $0 }.assumingMemoryBound(to: UnsafePointer<T>.self) // {$0}
        let ptr = b_ptr[0]
        let ptr_pte = ptr.pointee
        return ptr_pte
    }
    
}

/*
/*
 let c2 = method2pointer2(&m, type: type2)
 c2()
 let c3 = method2pointer3(&m, type: type3)
 */
@available(*, unavailable, message: "Error (2,3要同时跑才行🤔️❓)")
func method2pointer2<T>( _ method: inout Method, type: T.Type) -> T {
    let imp = method_getImplementation(method)
    
    /* 1 ``UnsafePointer<T>(imp)`` error: memory read failed */
    // var ptr = UnsafePointer<T>(imp)
    // var pte = ptr.pointee
    // return pte
    
    /* 2 Fatal error: Can't unsafeBitCast between types of different sizes */
    var c = unsafeBitCast(imp, to: type)
    return c
    
    /* 3 error: memory read failed */
    // let ptr = UnsafeRawPointer(imp).withMemoryRebound(to: type, capacity: 1) { $0 }
    // let ptr_pte = ptr.pointee
    // return ptr_pte
}

@available(*, unavailable, message: "Error")
func method2pointer3<T>( _ method: inout Method, type: T.Type) -> T? {
    let imp = method_getImplementation(method)
    // let b_ptr = withUnsafeBytes(of: imp) { $0 }.assumingMemoryBound(to: type)
    let b_ptr = withUnsafeBytes(of: imp) { $0 }.withMemoryRebound(to: type) { $0 }
    if b_ptr.count > 0 {
        let pte = b_ptr[0]
        return pte
    }
    return nil
}
*/
