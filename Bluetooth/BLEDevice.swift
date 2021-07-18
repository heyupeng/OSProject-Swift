//
//  BLEDevice.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/9.
//

import Foundation

import CoreBluetooth

class BTHUartService: NSObject {
    private(set) var service: CBService
    
    private(set) var txCharacteristic: CBCharacteristic?
    private(set) var rxCharacteristic: CBCharacteristic?
    
    required init(_ service: CBService) {
        self.service = service
    }
    
    static func match(service: CBService) -> BTHUartService? {
        if service.uuid.uuidString == BTHUUID.UartService.uuidString {
            return BTHUartService(service)
        }
        return nil
    }
    
    func didDiscoverUartCharacteristics() {
        for characteristics in service.characteristics ?? [] {
            let uuidString = characteristics.uuid.uuidString
            if uuidString == BTHUUID.UartService.txCharacteristicUUIDString {
                txCharacteristic = characteristics
            }
            else if uuidString == BTHUUID.UartService.rxCharacteristicUUIDString {
                rxCharacteristic = characteristics
            }
        }
    }
    
    internal var operationQueue: PeripheralOperationManager = PeripheralOperationManager()
}

extension BTHUartService: PeripheralOperationQueueProtocol {
    var peripheral: CBPeripheral? { self.service.peripheral }
    
    func checkDataIsCompleted(value: Data) -> Bool {
        return true
    }
    
    func write(_ value: Data, completed: @escaping (Data?) -> Void, error: ((Error) -> Void)? = nil) {
        guard let tx = txCharacteristic else {
            error?(BTH.Error(.characteristic, code: .invalidCharacteristic))
            return
        }
        var result: Data = Data()
        let updated: PeripheralCallbacks.UpdatedCallback = { args, isFinish  in
            guard let value = args.at(1, as: CBCharacteristic.self)?.value else {
                return
            }
            result.append(value)
            isFinish = self.checkDataIsCompleted(value: value)
            if isFinish {
                completed(result)
            }
        }
        let callbacks = PeripheralCallbacks(updated: updated, erorr: error)
        writeValueOperation(value, for: tx, type: .withResponse, callbacks)
    }
    
    func write(_ value: Data, next: (() -> Void)?, updated: ((Data?) -> Void)?, completion: ((Data?) -> Void)?, error: ((Error) -> Void)? = nil) {
        guard let tx = txCharacteristic else {
            error?(BTH.Error(.characteristic, code: .invalidCharacteristic))
            return
        }
        let callbacks = PeripheralCallbacks { arguments in
            next?()
        } updated: { arguments, isFinish in
            let res = arguments.at(1, as: CBCharacteristic.self)?.value
            updated?(res)
        } completed: { arguments in
            
        } erorr: { err in
            
        }
        writeValueOperation(value, for: tx, type: .withResponse, callbacks)
    }
}

extension BTHUartService: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard self.service.isEqual(to: service) else {
            return
        }
        didDiscoverUartCharacteristics()
        test()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.isEqual(to: rxCharacteristic) else {
            return
        }
        operationQueue.peripheral(peripheral, didUpdateValueFor: characteristic, error: error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.isEqual(to: txCharacteristic) else {
            return
        }
        operationQueue.peripheral(peripheral, didWriteValueFor: characteristic, error: error)
    }
}

class BLEDevice: NSObject, ConnectionHandleProtocol, BLEAccessibilityAdvertisement {
    
    var connectionHandle: BTH.ConnectionHandle<BLEDevice> = .init()
    var state: CBPeripheralState = .disconnected
    
    var peripheral: CBPeripheral!
    
    var advertisement: BLEAdvertisement = .init()
    var RSSI: NSNumber = 0
    
    var uartService: BTHUartService?
    
    typealias Callbacks = BTH.Callbacks<BLEDevice>
    private var nextCallbacks: Callbacks?
    
    convenience init(_ peripheral: CBPeripheral, _ advertisementData: [String : Any], _ RSSI: NSNumber) {
        self.init()
        self.peripheral = peripheral
        self.advertisement = BLEAdvertisement(advertisementData)
        self.RSSI = RSSI
        
    }
    
    var printer: PeripheralPrintExecutor = .init()
}

extension BLEDevice: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        defer {
            nextCallbacks?.invoke(self, err: error)
            nextCallbacks = nil
        }
        for service in peripheral.services ?? [] {
            if let uart = BTHUartService.match(service: service) {
                uartService = uart
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        defer {
            nextCallbacks?.invoke(self, err: error)
            nextCallbacks = nil
        }
        uartService?.peripheral(peripheral, didDiscoverCharacteristicsFor: service, error: error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
//        do {
            nextCallbacks?.invoke(self, err: error)
            nextCallbacks = nil
//        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        defer {
            nextCallbacks?.invoke(self, err: error)
            nextCallbacks = nil
        }
        uartService?.peripheral(peripheral, didUpdateValueFor: characteristic, error: error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        defer {
            nextCallbacks?.invoke(self, err: error)
            nextCallbacks = nil
        }
        uartService?.peripheral(peripheral, didWriteValueFor: characteristic, error: error)
    }
    
    // MARK: CBDescriptor
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
//        defer {
            nextCallbacks?.invoke(self, err: error)
            nextCallbacks = nil
//        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
//        defer {
            nextCallbacks?.invoke(self, err: error)
            nextCallbacks = nil
//        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
//        defer {
            nextCallbacks?.invoke(self, err: error)
            nextCallbacks = nil
//        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        // Todo:
    }
}

extension BLEDevice {
    func discoverServices(_ serviceUUIDs: [CBUUID]? = nil, _ next: ((BLEDevice)->Void)? = nil, error: BTH.Callbacks.Error? = nil) {
        nextCallbacks = .init(next, error: error)
        #if true
        peripheral.registerProxyTarget(printer)
        peripheral.registerProxyTarget(self)
        #else
        peripheral.delegate = self
        #endif
        peripheral.discoverServices(serviceUUIDs)
    }
    
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService, _ next: @escaping ((BLEDevice)->Void), error: BTH.Callbacks.Error? = nil) {
        nextCallbacks = .init(next, error: error)
        peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
    }
    
    func discoverDescriptors(for characteristic: CBCharacteristic, _ next: @escaping ((BLEDevice)->Void), error: BTH.Callbacks.Error? = nil) {
        nextCallbacks = .init(next, error: error)
        peripheral.discoverDescriptors(for: characteristic)
    }
    
    func readValue(for characteristic: CBCharacteristic, _ next: @escaping (BLEDevice)->Void, error: BTH.Callbacks.Error? = nil) {
        nextCallbacks = .init(next, error: error)
        peripheral.readValue(for: characteristic)
    }
    
    func readValue(for descriptor: CBDescriptor, _ next: @escaping (BLEDevice)->Void, error: BTH.Callbacks.Error? = nil) {
        nextCallbacks = .init(next, error: error)
        peripheral.readValue(for: descriptor)
    }
    
    func setNotifyValue(_ value: Bool, for characteristic: CBCharacteristic, _ next: @escaping (BLEDevice)->Void, error: BTH.Callbacks.Error? = nil) {
        nextCallbacks = .init(next, error: error)
        peripheral.setNotifyValue(value, for: characteristic)
    }
}

extension BLEDevice {
    var debugName: String {
        return "\( peripheral.identifier.uuidString) (\(peripheral.name ?? advertisement.localName ?? "N/A"))"
    }
}

extension BTHUartService {
    func test() {
        if txCharacteristic == nil {
            return
        }
        
        let data1 = Data(hexString:"01000400020023e778001e00")
        let data2 = Data(hexString:"070001000300b6e501")
        let data3 = Data(hexString:"08000100040022b901")
        
#if swift(>=5.0)
        guard let peripheral = service.peripheral else { return }
#else
        let peripheral = service.peripheral
#endif
        
        peripheral.setNotifyValue(true, for: rxCharacteristic!)
        
        write(data1) { data in
        } error: { error in
        }
        
        write(data2, next: nil, updated: nil, completion: nil)
        
        write(data3) { data in
        }
    }
}
