//
//  DelegateProxy.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/9.
//

import Foundation
import AppKit

protocol ProxyTargetBase {
    associatedtype ElementObject: AnyObject
    associatedtype Delegate
    
    var target: ElementObject? { get set }
    var respondSelectors: [Selector : Int] { get set }
}

extension ProxyTargetBase {
    func respondCount(for selector: Selector)  -> Int {
        if target != nil, let flag = respondSelectors[selector] { return flag }
        return 0
    }
    
    func implementation<CFunc>(for selector: Selector, type: CFunc.Type) -> CFunc? {
        if respondCount(for: selector) == 0 { return nil }
        if target == nil { return nil }
        let function = classMethodImp(target! as AnyObject, selector, type: type)
        if function == nil {
            fatalError("这里应该有方法的！！")
        }
        return function
    }
}

class ProxyTarget<E: AnyObject & NSObjectProtocol, D>: ProxyTargetBase {
    typealias ElementObject = E
    typealias Delegate = D
    
    weak var target: ElementObject?
    var respondSelectors: [Selector : Int] = [:]
    
    init(target: ElementObject, selectors: [Selector : Int] = [:]) {
        self.target = target
        self.respondSelectors = selectors
    }
    
    convenience init(target: ElementObject, protoSelectors: [Selector]) {
        var selectors: [Selector: Int] = [:]
        protoSelectors.forEach { s in
            if target.responds(to: s) == true {
                selectors[s] = 1
            }
        }
        self.init(target: target, selectors: selectors)
    }
}

private var ProtocolSelectors: [UnsafePointer<CChar> : [Selector]] = [:]

func loadProtocolSelectors(proto: Protocol) -> [Selector] {
    let key = protocol_getName(proto)
    if let selectorList = ProtocolSelectors[key] {
        return selectorList
    }
    let selectorList = protocolMethodSelectorList(proto)
    ProtocolSelectors[key] = selectorList
    print("Protocol ``\(String(utf8String: key)!)`` has \(selectorList.count) selectors .")
    return selectorList
}

protocol DelegateProxyBase: AnyObject {
    associatedtype ElementObject: AnyObject
    associatedtype Delegate
    
    var base: ElementObject? { get set }
    init(base: ElementObject)
}

extension DelegateProxyBase {
    var proto: Protocol {
        guard let proto = Delegate.self as AnyObject as? Protocol else {
            fatalError("It is not a vail protocol, that is a \(object_getClass(Delegate.self) ?? AnyObject.self) class!")
        }
        return proto
    }
    
    var selectorsForProto: [Selector] {
        return loadProtocolSelectors(proto: self.proto)
    }
}

extension DelegateProxyBase {
    static var identifier: UnsafeRawPointer {
        let identifier = ObjectIdentifier(Delegate.self)
        let bp = Int(bitPattern: identifier)
        return UnsafeRawPointer(bitPattern: bp)!
    }
    
    static func associatedDelegate<DP: DelegateProxyBase>(delegate: DP, for object: ElementObject) where DP.Delegate == Self.Delegate {
        objc_setAssociatedObject(object, self.identifier, delegate, .OBJC_ASSOCIATION_RETAIN)
    }
    
    static func associatedDelegate(for object: ElementObject) -> (Self)? {
        objc_getAssociatedObject(object, self.identifier) as? Self
    }
}

class DelegateProxy<EO: AnyObject, D>: NSObject, DelegateProxyBase {
    typealias ElementObject = EO
    typealias Delegate = D
    
    internal weak var base: ElementObject?
    
    var proxyTargets: [any ProxyTargetBase] = []

    required init(base: EO) {
        super.init()
        self.base = base
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        if selectorsForProto.contains(aSelector) {
            let count = invokeCount(forForwarding: aSelector)
            return count > 0
        }
        let _ = super.responds(to: aSelector)
        return true
    }
}

//protocol ObjectBase {
//
//}
// // A class has delegate should comform it, and redeclare ``Delegate``
//protocol DelegateOwnerBase: AnyObject {
//    associatedtype Delegate
//    var delegate: Delegate? { get set }
//}

//extension DelegateProxy where ElementObject: DelegateOwnerBase, ElementObject.Delegate == Delegate {
//    func setDelegate(delegate : Delegate?, for object: ElementObject) {
//        object.delegate = delegate
//    }
//}

extension DelegateProxy {
    func removeUnavailedForwardingTarget() {
        proxyTargets = proxyTargets.filter { p in
            return p.target != nil
        }
    }
    
    func invokeCount(forForwarding s: Selector) -> Int {
        return proxyTargets.reduce(0) { partialResult, proxyTarget in
            partialResult + proxyTarget.respondCount(for: s)
        }
    }
}

protocol DelegateProxyBase2: DelegateProxyBase {
    var proxyTargets: [any ProxyTargetBase] { get set }
    func removeUnavailedForwardingTarget()
}

extension DelegateProxyBase2 {
    static func proxy<DP: DelegateProxyBase>(for object: ElementObject, delegateProxy: DP.Type) -> Self where DP.ElementObject == ElementObject, DP.Delegate == Delegate {
        if let proxy = associatedDelegate(for: object) {
            return proxy
        }
        let proxy = DP.init(base: object)
        associatedDelegate(delegate: proxy, for: object)
        return proxy as! Self
    }
    
    static func registerProxyTarget<T: NSObjectProtocol, DP: DelegateProxyBase2>(_ target: T, for object: ElementObject, delegateProxy: DP.Type) where DP.ElementObject == ElementObject, DP.Delegate == Delegate {
        let serverProxy = proxy(for: object , delegateProxy: DP.self)
        serverProxy.registerProxy(target)
    }
    
    func registerProxy<T: NSObjectProtocol>(_ target: T) {
        let protoSelectors = selectorsForProto
        let proxy = ProxyTarget<T, Delegate>(target: target, protoSelectors: protoSelectors)
        proxyTargets.append(proxy)
        removeUnavailedForwardingTarget()
        (base as AnyObject).setValue(self, forKey: "delegate")
    }
}

extension DelegateProxyBase2 {
    func invokeMethod<T: CFuncScheme>(_ inv: CFuncInvocation<T>) {
        proxyTargets.forEach { p in
            let function = p.implementation(for: inv.selector, type: T.CFUNC.self)!
            inv.invoke(function, target: p.target)
        }
    }
    
    func invokeMethod<T: CFuncScheme>(_ scheme: T, selector: Selector) {
        proxyTargets.forEach { p in
            if p.target == nil { return }
            guard let function = p.implementation(for: selector, type: T.CFUNC.self) else {
                fatalError("找不到回调方法，赶紧检查是不是出错了～～")
//                return
            }
            scheme.invoke(function, target: p.target!, selector: selector)
        }
    }
}
