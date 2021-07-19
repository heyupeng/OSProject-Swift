//
//  BLEDevice.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/9.
//

import Foundation
import CoreBluetooth

protocol CBPeripheralAccessibilityProxy {
    var proxy: PeripheralDelegateProxy { get }
    func registerProxyTarget<T: CBPeripheralDelegate>(_ target: T)
}

extension CBPeripheralAccessibilityProxy where Self: CBPeripheral {
    var proxy: PeripheralDelegateProxy {
        PeripheralDelegateProxy.proxy(for: self)
    }
    func registerProxyTarget<T: CBPeripheralDelegate>(_ target: T) {
        PeripheralDelegateProxy.registerProxyTarget(target, for: self)
    }
}

extension CBPeripheral: CBPeripheralAccessibilityProxy {

}

/* CBPeripheralDelegate Selector List */
extension Selector {
    static let didUpdateName = sel_getUid("peripheralDidUpdateName:")
    static let didModifyServices = sel_getUid("peripheral:didModifyServices:")
    static let didUpdateRSSI =  sel_getUid("peripheralDidUpdateRSSI:error:")
    static let didReadRSSI =  sel_getUid("peripheral:didReadRSSI:error:")
    
    static let didDiscoverServices = sel_getUid("peripheral:didDiscoverServices:")
    static let didDiscoverIncludedServicesForService =  sel_getUid("peripheral:didDiscoverIncludedServicesForService:error:")
    static let didDiscoverCharacteristicsForService =  sel_getUid("peripheral:didDiscoverCharacteristicsForService:error:")

    static let didUpdateValueForCharacteristic =  sel_getUid("peripheral:didUpdateValueForCharacteristic:error:")
    static let didWriteValueForCharacteristic =  sel_getUid("peripheral:didWriteValueForCharacteristic:error:")
    static let didUpdateNotificationStateForCharacteristic =  sel_getUid("peripheral:didUpdateNotificationStateForCharacteristic:error:")
    
    static let didDiscoverDescriptorsForCharacteristic =  sel_getUid("peripheral:didDiscoverDescriptorsForCharacteristic:error:")
    static let didUpdateValueForDescriptor =  sel_getUid("peripheral:didUpdateValueForDescriptor:error:")
    static let didWriteValueForDescriptor =  sel_getUid("peripheral:didWriteValueForDescriptor:error:")
    
    static let isReadyToSendWriteWithoutResponse =  sel_getUid("peripheralIsReadyToSendWriteWithoutResponse:")
    static let didOpenL2CAPChannel = sel_getUid("peripheral:didOpenL2CAPChannel:error:")
}

class PeripheralDelegateProxy: DelegateProxy<CBPeripheral, CBPeripheralDelegate>, DelegateProxyBase2 {    
    private weak var peripheral: CBPeripheral?
    
    
    required init(base: ElementObject) {
        super.init(base: base)
        self.peripheral = base
    }
}

extension PeripheralDelegateProxy {
    static func proxy(for object: ElementObject) -> Self {
        proxy(for: object , delegateProxy: Self.self)
    }
    
    static func registerProxyTarget<T: NSObjectProtocol>(_ target: T, for object: ElementObject) {
        registerProxyTarget(target, for: object, delegateProxy: Self.self)
    }
}

extension PeripheralDelegateProxy {
//    private func resetforwardingSelector(_ selector: Selector) {
//        if forwardingSelector == selector {
//            forwardingSelector = nil
//        }
//    }
//
//    func setforwardingSelector(_ selector: Selector) {
//        forwardingSelector = selector
//    }
    
    // 1 arg
    func invokeMethod(selector: Selector, _ peripheral: CBPeripheral) {
        let scheme = CFuncScheme1(arguments: (peripheral))
        invokeMethod(scheme, selector: selector)
    }
    
    // 2 args
    func invokeMethod(selector: Selector, _ peripheral: CBPeripheral, _ argument2: Any?) {
        let scheme = CFuncScheme2(arguments: (peripheral, argument2))
        invokeMethod(scheme, selector: selector)
    }
    
    func invokeMethod(selector: Selector, _ peripheral: CBPeripheral, error: Error?) {
        invokeMethod(selector: selector, peripheral, error)
    }
    
    // 3 args
    func invokeMethod(selector: Selector, _ peripheral: CBPeripheral, _ argument2: AnyObject?, error: Error?) {
        let scheme = CFuncScheme3(arguments: (peripheral, argument2, error))
        invokeMethod(scheme, selector: selector)
    }
}

extension PeripheralDelegateProxy: CBPeripheralDelegate {
    @available(macOS 10.9, *)
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        let s = #selector( CBPeripheralDelegate.peripheralDidUpdateName(_:) )
        invokeMethod(selector: s, peripheral)
    }
    
    @available(macOS 10.9, *)
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        let s = #selector( CBPeripheralDelegate.peripheral(_:didModifyServices:) )
        invokeMethod(selector: s, peripheral, invalidatedServices as AnyObject)
    }

    @available(macOS, introduced: 10.7, deprecated: 10.13)
    func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: Error?) {
        let s = #selector( CBPeripheralDelegate.peripheral(_:didReadRSSI:error:))
        invokeMethod(selector: s, peripheral, error: error)
    }
    
    @available(macOS 10.13, *)
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        let s = #selector( CBPeripheralDelegate.peripheral(_:didReadRSSI:error:) )
        invokeMethod(selector: s, peripheral, RSSI, error: error)
    }
    
    @available(macOS 10.7, *)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let s = #selector(CBPeripheralDelegate.peripheral(_:didDiscoverServices:))
        invokeMethod(selector: s, peripheral, error: error)
    }
    
    // MARK: CBService
    @available(macOS 10.7, *)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        let s = #selector( CBPeripheralDelegate.peripheral(_:didDiscoverIncludedServicesFor:error:) )
        invokeMethod(selector: s, peripheral, service, error: error)
    }
    
    @available(macOS 10.7, *)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let s = #selector( CBPeripheralDelegate.peripheral(_:didDiscoverCharacteristicsFor:error:) )
        invokeMethod(selector: s, peripheral, service, error: error)
    }
    
    // MARK: CBCharacteristic
    @available(macOS 10.7, *)
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        invokeMethod(selector: .didUpdateValueForCharacteristic, peripheral, characteristic, error: error)
    }

    @available(macOS 10.7, *)
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        invokeMethod(selector: .didWriteValueForCharacteristic, peripheral, characteristic, error: error)
    }
    
    @available(macOS 10.7, *)
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        let s: Selector = .didUpdateNotificationStateForCharacteristic
        invokeMethod(selector: s, peripheral, characteristic, error: error)
    }
    
    // MARK: CBDescriptor
    @available(macOS 10.7, *)
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        let s: Selector = .didDiscoverDescriptorsForCharacteristic
        invokeMethod(selector: s, peripheral, characteristic, error: error)
    }
    
    @available(macOS 10.7, *)
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        let s: Selector = .didUpdateValueForDescriptor
        invokeMethod(selector: s, peripheral, descriptor, error: error)
    }

    @available(macOS 10.7, *)
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        let s: Selector = .didWriteValueForDescriptor
        invokeMethod(selector: s, peripheral, descriptor, error: error)
    }
    
    @available(macOS 10.7, *)
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        let s: Selector = .isReadyToSendWriteWithoutResponse
        invokeMethod(selector: s, peripheral)
    }
    
    @available(macOS 10.13, *)
    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        let s: Selector = .didOpenL2CAPChannel
        invokeMethod(selector: s, peripheral, channel, error: error)
    }
    
    ///
    /// ``peripheral:didReceiveTimeSyncWithReferenceTime:localAbsolute:remoteAbsolute:receiveTime:GMTDelta:error:``
    func peripheral(_ peripheral: CBPeripheral, didReceiveTimeSyncWith referenceTime:Date, localAbsolute:Any, remoteAbsolute:Any, receiveTime:Date, GMTDelta:AnyObject, error: Error?) {
        print("123")
    }
}

