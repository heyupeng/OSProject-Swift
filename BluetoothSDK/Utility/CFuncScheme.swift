//
//  CFuncScheme.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/9.
//

import Foundation

protocol CFuncScheme {
    associatedtype CFUNC
    associatedtype ARGS
    var arguments: ARGS { get set }
    
    func invoke(_ implementation: CFUNC, target: AnyObject, selector: Selector)
}

struct CFuncScheme1: CFuncScheme {
    typealias CFUNC = @convention(c) (AnyObject, Selector, AnyObject) -> Void
    typealias ARGS = (AnyObject)
    var arguments: ARGS
    
    func invoke(_ implementation: CFUNC, target: AnyObject, selector: Selector) {
        implementation(target, selector, arguments)
    }
}

struct CFuncScheme2: CFuncScheme {
    typealias CFUNC = @convention(c) (AnyObject, Selector, AnyObject, Any?)->Void
    typealias ARGS = (AnyObject, Any?)
    var arguments: ARGS
    
    func invoke(_ implementation: CFUNC, target: AnyObject, selector: Selector) {
        implementation(target, selector, arguments.0, arguments.1)
    }
}

struct CFuncScheme3: CFuncScheme {
    typealias CFUNC = @convention(c) (AnyObject, Selector, AnyObject, AnyObject?, Any?)->Void
    typealias ARGS = (AnyObject, AnyObject?, Any?)
    var arguments: ARGS
    
    func invoke(_ implementation: CFUNC, target: AnyObject, selector: Selector) {
        implementation(target, selector, arguments.0, arguments.1, arguments.2)
    }
}

struct CFuncInvocation<Scheme: CFuncScheme> {
    var scheme: Scheme
    weak var target: AnyObject?
    var selector: Selector
    var implementation: Scheme.CFUNC!
    
    init(scheme: Scheme, target: AnyObject? = nil, selector: Selector, implementation: Scheme.CFUNC!) {
        self.scheme = scheme
        self.target = target
        self.selector = selector
        self.implementation = implementation
    }
    
    init(scheme: Scheme, target: AnyObject? = nil, selector: Selector) {
        self.scheme = scheme
        self.target = target
        self.selector = selector
    }
}

extension CFuncInvocation {
    func invoke() {
        if target == nil || implementation == nil { return }
        scheme.invoke(implementation, target: target!, selector: selector)
    }
    
    func invoke(_ implementation: Scheme.CFUNC, target: AnyObject?) {
        if target == nil { return }
        scheme.invoke(implementation, target: target!, selector: selector)
    }
}

typealias CFunc1 = @convention(c) (AnyObject, Selector, AnyObject)->Void
typealias CFunc2 = @convention(c) (AnyObject, Selector, AnyObject, Any?)->Void
typealias CFunc3 = @convention(c) (AnyObject, Selector, AnyObject, AnyObject?, Any?)->Void
