//
//  PeripheralPrintExecutor.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/9.
//

import Foundation

import CoreBluetooth

fileprivate class Print {
    var errorSymbols: String = ""
    
    func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        Swift.print(items, separator: separator, terminator: terminator)
    }
    
    func funcname(prefix: String = "[callback]", separator: String = " ", funcname: String = #function) {
        print(prefix + separator + funcname)
    }
    
    func error(_ items: Any..., prefix: String = "", separator: String = " ") {
        if prefix.count > 0 { append(prefix + separator) }
        append(errorSymbols)
        print(items)
    }
    
    func append(_ items: Any..., separator: String = " ") {
        print(items, separator: separator, terminator: "")
    }
}

class PeripheralPrintExecutor: NSObject, CBPeripheralDelegate {
    fileprivate let printer: Print = .init()
    
    func printError(_ error: Error?) {
        guard error != nil else { return }
        printer.error("There callback has a error. \(error!)")
    }
    
    func print(_ item: Any..., prifix: String = " ") {
        printer.append(prifix)
        printer.print(item[0])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        printer.funcname()
        guard peripheral.services != nil else {
            printer.error( "services is empty")
            return
        }
        for service in peripheral.services! {
            printer.print(" service uuid: " + service.uuid.uuidString + " (\(service.uuid))")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        printer.funcname()
        printError(error)
        guard isEmpty(error) else {
            return
        }
        guard service.characteristics?.isEmpty == false else {
            printer.error("service.characteristics is empty.")
            return
        }
        for ch in service.characteristics! {
            print("characteristic \(ch.uuid) <\(ch.uuid.uuidString)>.")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        printer.funcname()
        printError(error)
        print("`\(characteristic.uuid.uuidString)` did update notification state: \(characteristic.isNotifying)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        printer.funcname()
        printError(error)
        print("`\(characteristic.uuid.uuidString)` did update value: \(characteristic.value?.hexString ?? "nil")")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        printer.funcname()
        printError(error)
        print("`\(characteristic.uuid.uuidString)` did write value: \(characteristic.value?.hexString ?? "nil")")
    }
    
    // MARK: CBDescriptor
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        printer.funcname()
        printError(error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        printer.funcname()
        printError(error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        printer.funcname()
        printError(error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        printer.funcname()
        print("\(invalidatedServices).")
    }
    
    @objc func peripheral(_ peripheral: CBPeripheral, didReceiveTimeSyncWith referenceTime:Any, localAbsolute:Any, remoteAbsolute:Any, receiveTime:Any, GMTDelta:AnyObject, error: Error?) {
        #selector(self.peripheral(_:didReceiveTimeSyncWith:localAbsolute:remoteAbsolute:receiveTime:GMTDelta:error:))
        print("123")
    }
}
