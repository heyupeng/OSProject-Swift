//
//  PeripheralOperation.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/9.
//

import Foundation

import CoreBluetooth

struct PeripheralCallbacks {
    struct Arguments {
        private let args: [CVarArg]
        var count: Int { args.count }
        
        init(_ args: CVarArg...) {
            self.args = args
        }
        
        init(_ args: [CVarArg]) {
            self.args = args
        }
        
        subscript(idx: Int) -> CVarArg {
            return  args[idx]
        }
        
        func at<T>(_ idx: Int, as: T.Type) -> T? {
            let value =  args[1]
            return value as? T
        }
    }
    
    typealias Callback = (Arguments) -> Void
    typealias UpdatedCallback = (Arguments, inout Bool) -> Void
    typealias ErrorCallback = (Error) -> Void
    
    var next: Callback?
    var updated: UpdatedCallback?
    var completed: Callback?
    var erorr: ErrorCallback?
}

struct PeripheralOperation {
    enum Event {
        case read(_ characteristic: CBCharacteristic)
        case write(_ data: Data, _ characteristic: CBCharacteristic, _ type: CBCharacteristicWriteType)
    }
    
    var isExecuted: Bool = false
    var isFinish: Bool = false
    
    var operationEvent: Event
    
    var callbacks: PeripheralCallbacks?
    
    var isActivating: Bool {
        return isExecuted == true && isFinish == false
    }
    init(_ operationEvent: Event, callbacks: PeripheralCallbacks? = nil) {
        self.operationEvent = operationEvent
        self.callbacks = callbacks
    }
}

extension PeripheralOperation {
    
    func isExcutable(_ peripheral: CBPeripheral?) -> Bool {
        guard let peripheral = peripheral,
              peripheral.state == .connected
        else {
            return false
        }
        return true
    }
    
    func execute(_ peripheral: CBPeripheral) -> Bool {
        if !isExcutable(peripheral) {
            return false
        }
        switch operationEvent {
        case .read(let characteristic):
            peripheral.readValue(for: characteristic)
            break
        case .write(let data, let characteristic, let type):
            peripheral.writeValue(data, for: characteristic, type: type)
            break
        }
        return true
    }
    
    func matchRead(_ charateristic: CBCharacteristic) -> Bool {
        switch operationEvent {
        case .read(let ch): return charateristic == ch
        default: return false
        }
    }
    
    func matchWrite(_ charateristic: CBCharacteristic) -> Bool {
        switch operationEvent {
        case .write(_, let ch, _): return charateristic == ch
        default: return false
        }
    }
    
    var type: CBCharacteristicWriteType? {
        switch operationEvent {
        case .write(_, _, let t): return t
        default: return nil
        }
    }
}

struct PeripheralOperationManager {
    private(set) var currentOp: PeripheralOperation?
    private var operations: [PeripheralOperation] = []
    
    mutating func reset() {
        currentOp = nil
        operations = []
    }
    
    mutating func appendOperation(_ operation: PeripheralOperation, peripheral: CBPeripheral) {
        operations.append(operation)
        
        if operations.count == 1 {
            executeFirstOperation(peripheral)
        }
    }
    
    private mutating func executeFirstOperation(_ peripheral: CBPeripheral) {
        guard let first = operations.first, first.isExecuted == false else {
            return
        }
        currentOp = first
        currentOp?.isExecuted = true
//        operations[0].isExecuted = true
        
        if !first.execute(peripheral) {
            let err = BTH.Error(.peripheral, code: .peripheralDisconnected)
            print("----- Peripheral is invaild. -----")
            first.callbacks?.erorr?(err)
        }
    }
    
    private mutating func executeNextOperation(_ peripheral: CBPeripheral) {
        guard let _ = operations.first else {
            return
        }
        
        currentOp?.isFinish = true
        currentOp = nil
//        operations[0].isFinish = true
        operations.removeFirst()
        
        executeFirstOperation(peripheral)
    }
    
    mutating func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let operation = currentOp, operation.isActivating else {
            return
        }
        // Todo: 此处不作分包校验。外部可通过 ``callbacks?.updated?`` 自行判断。
        if operation.matchRead(characteristic) {
            guard error == nil else {
                operation.callbacks?.erorr?(error!)
//                executeNextOperation(peripheral)
                return
            }
            operation.callbacks?.next?(.init(peripheral, characteristic))
            executeNextOperation(peripheral)
        }
        else {
            var isFinish = true
            if operation.callbacks?.updated != nil {
                operation.callbacks?.updated?(.init(peripheral, characteristic), &isFinish)
            }
            if isFinish {
                operation.callbacks?.completed?(.init(peripheral, characteristic))
                executeNextOperation(peripheral)
            }
        }
    }
    
    mutating func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let operation = currentOp, operation.isActivating,
              operation.matchWrite(characteristic) else {
            return
        }
        guard error == nil else {
            operation.callbacks?.erorr?(error!)
//            executeNextOperation(peripheral)
            return
        }
        operation.callbacks?.next?(.init(peripheral, characteristic))
        
        var isFinish = false
        if operation.type == .withoutResponse  {
            isFinish = true
            
        } else if operation.callbacks?.updated == nil, operation.callbacks?.completed == nil {
            isFinish = true
        }
        
        if isFinish {
            operation.callbacks?.completed?(.init(peripheral, characteristic))
            executeNextOperation(peripheral)
        }
    }
}

protocol PeripheralOperationQueueProtocol: CBPeripheralDelegate {
    var operationQueue: PeripheralOperationManager { set get }
    var peripheral: CBPeripheral? { get }
}

extension PeripheralOperationQueueProtocol {
    func appendOperation(_ operation: PeripheralOperation) {
        operationQueue.appendOperation(operation, peripheral: peripheral!)
    }
    
    func readValueOperation(for characteristic: CBCharacteristic, _ callbacks: PeripheralCallbacks) {
        let operation = PeripheralOperation(.read(characteristic), callbacks: callbacks)
        self.appendOperation(operation)
    }
    
    func writeValueOperation(_ value: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType, _ callbacks: PeripheralCallbacks) {
        let operation = PeripheralOperation(.write(value, characteristic, type), callbacks: callbacks)
        self.appendOperation(operation)
    }
    
    func writeValueOperation(_ value: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType,  next: (PeripheralCallbacks.Callback)?, updated: (PeripheralCallbacks.UpdatedCallback)?, completion: (PeripheralCallbacks.Callback)?, error: (PeripheralCallbacks.ErrorCallback)? = nil) {
        
        let callbacks = PeripheralCallbacks(next: next, updated: updated, completed: completion, erorr: error)
        writeValueOperation(value, for: characteristic, type: type, callbacks)
    }
}
