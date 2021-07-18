//
//  CBCharacteristic+.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/9.
//

import Foundation
import CoreBluetooth

extension CBCharacteristicProperties: OptionSetComponenents {
    static var allOptions: [CBCharacteristicProperties] {
        if #available(macOS 10.9, *) {
            return [.broadcast, .read, .writeWithoutResponse, .write, .notify, .indicate, .authenticatedSignedWrites, .extendedProperties, .notifyEncryptionRequired, .indicateEncryptionRequired]
        } else {
            return [.broadcast, .read, .writeWithoutResponse, .write, .notify, .indicate, .authenticatedSignedWrites, .extendedProperties]
        }
    }
}

extension CBCharacteristicProperties: CustomStringConvertible {
    public var description: String {
        switch self {
        case .broadcast:    return "broadcast"
        case .read:         return "read"
        case .writeWithoutResponse: return "writeWithoutResponse"
        case .write:                return "write"
        case .notify:               return "notify"
        case .indicate:             return "indicate"
        case .authenticatedSignedWrites:    return "authenticatedSignedWrites"
        case .extendedProperties:           return "extendedProperties"
        case .notifyEncryptionRequired:     return "notifyEncryptionRequired" // 1 << 7
        case .indicateEncryptionRequired:   return "indicateEncryptionRequired" // 1 << 8
        default:
            let cmps = self.components.map { $0.description }.joined(separator: ",")
            if cmps.count > 0 { return cmps }
            return "unkown"
        }
    }
}

extension CBCharacteristic {
    var stringValue: String? {
        guard let value = self.value else { return nil }
        let name = self.uuid.description
        if name.suffix(6) == "String" {
            return value.ascii
        }
        else if name.suffix(5) == "Level" {
            return "\(value.toInteger(to: UInt8.self))"
        }
        return value.hexString
    }
}

protocol CBPeripheralAccessibility {
    associatedtype Vector
    
    func service(_ vector: Vector) -> CBService?
    
    func characteristic(_ vector: Vector) -> CBCharacteristic?
    
    func descriptor(_ vector: Vector) -> CBDescriptor?
}

extension CBPeripheral: CBPeripheralAccessibility {
    struct AttributeVector {
        var x: Int = -1 // default = -1, means nil.
        var y: Int = -1
        var z: Int = -1
    }
    typealias Vector = AttributeVector
}

extension CBPeripheralAccessibility where Self: CBPeripheral {
    func service(_ vector: Vector) -> CBService? {
        guard vector.x >= 0 else { return nil }
        guard let services = services, services.count > vector.x else { return nil }
        return services[vector.x]
    }
    
    func characteristic(_ vector: Vector) -> CBCharacteristic? {
        guard vector.y >= 0, let service = service(vector) else { return nil }
        guard let characteristics = service.characteristics, characteristics.count > vector.y else { return nil }
        return characteristics[vector.y]
    }
    
    func descriptor(_ vector: Vector) -> CBDescriptor? {
        guard vector.z >= 0, let characteristic = characteristic(vector) else { return nil }
        guard let descriptors = characteristic.descriptors, descriptors.count > vector.z else { return nil }
        return descriptors[vector.z]
    }
}
