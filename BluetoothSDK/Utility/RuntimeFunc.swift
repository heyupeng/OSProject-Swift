//
//  BLEDevice.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/9.
//

import Foundation

func protocolMethodSelectorList(_ proto: Protocol) -> [Selector] {
    var protocolSelectors: [Selector] = []
    var count: UInt32 = 0
    let list = protocol_copyMethodDescriptionList(proto, false, true, &count)
    for idx in 0..<Int(count) {
        let description = list![idx]
        protocolSelectors.append(description.name!)
    }
    return protocolSelectors
}

func classMethodSelectorList(_ cls: AnyClass?) -> [Selector] {
    var selectors: [Selector] = []
    var count: UInt32 = 0
    let list = class_copyMethodList(cls, &count)
    for idx in 0..<Int(count) {
        let method = list![idx]
        let selector = method_getName(method)
        selectors.append(selector)
    }
    return selectors
}

func classMethod(_ cls: AnyClass, selector: Selector) -> Method? {
    var count: UInt32 = 0
    let list = class_copyMethodList(cls, &count)
    for idx in 0..<Int(count) {
        let method = list![idx]
        let sel = method_getName(method)
        if sel != selector { continue }
        return method
    }
    return nil
}

func classMethodImp<CTunc>(_ object: AnyObject, _ selector: Selector, type: CTunc.Type) -> CTunc? {
    let method = classMethod(object.classForCoder, selector: selector)
    if method == nil {
        return nil
    }
    let function = methodImplementation(method!, to: type)
    return function
}

func methodImplementation<T>(_ method: Method, to type: T.Type) -> T {
    var imp = method_getImplementation(method)
    let ptr = withUnsafePointer(to: &imp) { $0.withMemoryRebound(to: type, capacity: 1) { $0 } }
    let ptr_pte = ptr.pointee
    return ptr_pte
}
