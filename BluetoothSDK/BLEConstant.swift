//
//  BLEDevice.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/9.
//

import Foundation

import CoreBluetooth

struct BTHUUID {
    struct UartService {
        static let uuidString = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
        static let txCharacteristicUUIDString = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
        static let rxCharacteristicUUIDString = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
    }
    
    static let DeviceInfomation = "180A"
    static let ManufacturerNameString = "2A29"
    static let ModelNumberString = "2A24"
    static let SerialNumberString = "2A25"
    static let HardwareRevisionString = "2A27"
    static let FirmwareRevisionString = "2A26"
    static let SoftwareRevisionString = "2A28"
    static let SystemID = "2A23"
    static let IEEERegulatoryCertification = "2A2A"
    static let PnPID = "2A50"
    
    static let Battery = "180F"
    static let BatteryLevel = "2A19"
    
    static let CurrentTime_S = "1805"
    static let CurrentTime_C = "2A2B"
    static let LocalTimeInformation = "2A0F"
}

struct BTH {
    
}

extension BTH {
    public enum Domain : String {
        case manager = "manager"
        case peripheral = "peripheral"
        case service = "service"
        case characteristic = "characteristic"
        case descriptor = "descriptor"
        
        var domain: String {
            return "com.bluetooth." + rawValue
        }
    }
    
    public enum ErrorCode : Int, @unchecked Sendable {
        // Error of manager op
        case unkown = 10
        case authorizationDenied = 11
        case opertaionStopAsPoweredOff
        case disconnectAsPoweredOff
        case failToConnect
        // Error of peripheral op
        case peripheralDisconnected = 101
        case invalidCharacteristic
        case invalidDescriptor
        
        var localizedDescription: String {
            switch self {
            case .authorizationDenied: return "Bluetooth authorization is denied"
            case .opertaionStopAsPoweredOff: return "Bluetooth is powered off"
            case .disconnectAsPoweredOff: return "Bluetooth is powered off"
            case .failToConnect: return "Fail to connect peripheral"
            case .peripheralDisconnected: return "The peripheral is disconnected."
            case .invalidCharacteristic: return "The characteristic is invalid."
            case .invalidDescriptor: return "The descriptor is invalid."
            default: return "Unkown error."
            }
        }
    }
    
    static func Error(_ domain: BTH.Domain, code: BTH.ErrorCode) -> Error {
        return NSError(domain: domain.domain, code: code.rawValue, userInfo: [NSLocalizedFailureErrorKey: code.localizedDescription]) as Error
    }
    
    static func Error(_ state: CBManagerState) -> Error? {
        switch state {
        case .poweredOn: return nil
        case .poweredOff: return Error(.manager, code: .opertaionStopAsPoweredOff)
        case .unauthorized: return Error(.manager, code: .authorizationDenied)
        default:
            return Error(.manager, code: .unkown)
        }
    }
}

extension BTH {
    typealias Closure1<Element> = (Element)-> Void
    typealias Closure2<Element1, Element2> = (Element1, Element2)-> Void
    typealias Closure3<Element1, Element2, Element3> = (Element1, Element2, Element3)-> Void
    
    struct Callbacks<T> {
        typealias Element = T
        typealias Next = Closure1<Element>
        typealias Error = (Swift.Error) -> Void
        
        private var next: Next?
        private var error: Error?
        
        init(_ next: Closure1<Element>? = nil, error: Error? = nil) {
            self.next = next
            self.error = error
        }
        
        func invoke(_ sender: Element, err: Swift.Error? = nil) {
            if !isEmpty(err) {
                invokeError(err!)
            }
            else {
                invokeNext(sender)
            }
        }
        
        func invokeNext(_ sender: Element) {
            next?(sender)
        }
        
        func invokeError(_ err: Swift.Error) {
            error?(err)
        }
    }
    
    struct ConnectionHandle<T> {
        typealias Callbacks = BTH.Callbacks<T>
        fileprivate var connected: Callbacks?
        fileprivate var disconnected: Callbacks?
    }
}

protocol ConnectionHandleProtocol<Value>: NSObjectProtocol {
    associatedtype Value
    var connectionHandle: BTH.ConnectionHandle<Value> { get set }
    var state: CBPeripheralState { get set }
    
}

extension ConnectionHandleProtocol {
    func observeDisconnected(_ next: @escaping BTH.ConnectionHandle<Value>.Callbacks.Next, error: BTH.ConnectionHandle<Value>.Callbacks.Error?) {
        setDisconnectedHandle(.init(next, error: error))
    }
    
    func observeConnected(_ next: @escaping BTH.ConnectionHandle<Value>.Callbacks.Next, error: BTH.ConnectionHandle<Value>.Callbacks.Error?) {
        setConnectedHandle(.init(next, error: error))
    }
    
    func setDisconnectedHandle(_ handler: BTH.ConnectionHandle<Value>.Callbacks) {
        connectionHandle.disconnected = handler
    }
    
    func setConnectedHandle(_ handler: BTH.ConnectionHandle<Value>.Callbacks) {
        connectionHandle.connected = handler
    }
    
    /// Update operation state
    func doing(_ state: CBPeripheralState) {
        self.state = state
    }
    
    func invokeDisconnected(_ sender: Value, _ err: Error?) {
        connectionHandle.disconnected?.invoke(sender, err: err)
    }
    
    func invokeconnected(_ sender: Value, _ err: Error? = nil) {
        connectionHandle.connected?.invoke(sender, err: err)
    }
}

extension ConnectionHandleProtocol where Self == Self.Value {
    func didConnect() {
        doing(.connected)
        connectionHandle.connected?.invokeNext(self)
    }
    
    func didFailToConnect(_ error: Error) {
        doing(.disconnected)
        connectionHandle.connected?.invokeError(error)
    }
    
    func didDisconnect(_ error: Error? = nil) {
        doing(.disconnected)
        invokeDisconnected(self, error)
    }
}
