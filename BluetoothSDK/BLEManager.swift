//
//  BLEMamager.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/9.
//

/*
 1.
 [default] Failed to get state for list identifier com.apple.LSSharedFileList.ApplicationRecentDocuments Error: Error Domain=NSPOSIXErrorDomain Code=1 "Operation not permitted" (Access to list denied) UserInfo={NSDebugDescription=Access to list denied}
 Todo:CODE_SIGN_IDENTITY => development
 */

import Foundation
import CoreBluetooth


class BLEManager: NSObject {
    
    let bleQueue = DispatchQueue.init(label: "com.bluetooth.queue")
    var manager: CBCentralManager!
    var isEnabled: Bool { manager.state == .poweredOff }
    
    let semaphore = DispatchSemaphore(value: 1)
    private(set) var isReadyToWork = false
    
//    var discovers: [BLEDevice] = []
    
    var discovers: [UUID: BLEDevice] = [:]
    
    typealias BLECallback = BTH.Closure1<(BLEManager, BLEDevice)>
    typealias BLEErrorCallback = BTH.Closure1<(BLEDevice, Error?)>
    class BLEConnectionCallbacks: NSObject {
        var connect: BLECallback?
        var failToConnect: BLEErrorCallback?
        var disconnect: BLEErrorCallback?
    }
    
    private var scanCallbacks: BTH.Callbacks<(BLEManager, BLEDevice)>?
    
    // <UUIDString, BLE, BLEConnection>
    private var connectionCache: Cache<String, (BLEDevice, BLEConnectionCallbacks)> = .init()
    
    // work state
    var isScanning: Bool = false
    var isConnecting: Bool      { return countInCache(.connecting) > 0 }
    var isDisconnecting: Bool   { return countInCache(.disconnecting) > 0 }
}

extension BLEManager {
    func countInCache(_ state: CBPeripheralState) -> Int {
        var count = 0
        connectionCache.values.forEach { (device, callbacks) in
            if device.state == state { count += 1 }
        }
        return count
    }
    
    var isDeniedAuthorization: Bool {
        let authorization: CBManagerAuthorization
        if #available(macOS 10.15, *) {
            authorization = CBManager.authorization
        } else {
            authorization = manager.authorization
        }
        return authorization == .denied
    }
    
    func checkBLEEabled() -> Error? {
        self.prepareForManager()
        if isDeniedAuthorization {
            return BTH.Error(.manager, code: .authorizationDenied)
        }
        if manager.state == .unknown {
            semaphore.wait()
            semaphore.signal()
        }
        return BTH.Error(manager.state)
    }
    
    func createManagerAsNeed() {
        if (manager != nil) { return }
        manager = CBCentralManager(delegate: self, queue: bleQueue)
    }
    
    /// 中心管理器完成实例化后，第一次调用``centralManagerDidUpdateState(_:)``回调。
    func didReadyToWork() {
        if isReadyToWork == true { return }
        isReadyToWork = true
        semaphore.signal()
    }
    
    func prepareForManager() {
        if isReadyToWork == true { return }
        
        print("== 1 ==")
        let res = semaphore.wait(timeout: DispatchTime.now() + 30)
        guard res == .success else {
            print("== 2 ==", "wait timeout!")
            return
        }
        print("== 2 ==")
        // `` singal `` will be invoked after manager'state updated firstly.
        createManagerAsNeed()
    }
    
    func prepareForScan() {
        self.discovers = [:]
        isScanning = true
    }
    
    /// Maybe, there are some connected device before powwer-off
    func loseConnectionsAsPoweredOff() {
        if manager.state != .poweredOff { return }
        
        if isScanning {
            isScanning = false
            scanCallbacks?.invokeError(BTH.Error(.manager, code: .opertaionStopAsPoweredOff))
        }
        
        let devices = connectionCache.values
        connectionCache.removeAll()
        for (device, callbacks) in devices {
            if !(device.state == .connecting || device.state == .connected) {
                continue
            }
            let err = BTH.Error(.manager, code: .disconnectAsPoweredOff)
            callbacks.disconnect?((device, err))
            device.didDisconnect(err)
        }
    }
}

extension BLEManager {
    func scan(_ next: BLECallback? = nil, error: ((Error)-> Void)?) {
        self.scanCallbacks = .init(next, error: error)
        
        if let err = checkBLEEabled() {
            error?(err)
            return
        }
        
        semaphore.wait()
        self.prepareForScan()
        
        let options: [String: Any] = [
            CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: false),
        ]
        manager.scanForPeripherals(withServices: nil, options: options);
        
        semaphore.signal()
    }
    
    func stopScan() {
        manager.stopScan()
        isScanning = false
        scanCallbacks = nil
    }
    
    func connect(_ device: BLEDevice, _ connected: BLECallback? = nil, fail: BLEErrorCallback? = nil) {
        if device.peripheral.state == .disconnected {
            print("connect:", device.debugName)
            var callbacks = BLEConnectionCallbacks()
            callbacks.connect = connected
            callbacks.failToConnect = fail
            connectionCache.insert((device, callbacks))
            
            device.doing(.connecting)
            manager.connect(device.peripheral, options: nil)
        }
    }
    
    func disconnect(_ device: BLEDevice, _ disconnected: BLEErrorCallback? = nil) {
        if device.peripheral.state != .disconnected {
            print("disconnect:", device.debugName)
            connectionCache[device.peripheral]?.1.disconnect = disconnected
            
            device.doing(.disconnecting)
            manager.cancelPeripheralConnection(device.peripheral)
        }
    }
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("[Callback]: Manager did update state \(central.state.debugDescription)")
        
        didReadyToWork()
        
        loseConnectionsAsPoweredOff()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if let device = discovers[peripheral.identifier] {
            device.addRSSI(rssi: RSSI)
            return
        }
        
        let device = BLEDevice(peripheral, advertisementData, RSSI)
        discovers[peripheral.identifier] = device
        
        print( "(\(discovers.count))", device.debugName )
        
        scanCallbacks?.invokeNext((self, device))
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("[Callback]: Manager did connect peripheral")
        guard let (device, callbacks) = connectionCache[peripheral] else {
            return
        }
        device.didConnect()
        callbacks.connect?((self, device))
        callbacks.connect = nil
        callbacks.failToConnect = nil
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("[Callback]: Manager did fail to connect peripheral")
        guard let (device, callbacks) = connectionCache.remove(peripheral) else {
            return
        }
        let err = error ?? BTH.Error(.manager, code: .failToConnect)
        device.didFailToConnect(err)
        callbacks.failToConnect?((device, err))
        callbacks.failToConnect = nil
        callbacks.connect = nil
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("[Callback]: Manager did disconnect peripheral")
        if error != nil { print("  \(error!)") }
        
        guard let (device, callbacks) = connectionCache.remove(peripheral) else {
            return
        }
        if device.state != .disconnecting {
            print("\(device.debugName) has disconnected by itself.")
        }
        
        device.didDisconnect(error)
        callbacks.disconnect?((device, error))
        callbacks.disconnect = nil
    }
}

extension Cache where K == String, V == (BLEDevice, BLEManager.BLEConnectionCallbacks) {
    mutating func insert(_ element: V) {
        self[element.0.peripheral.identifier.uuidString] = element
    }
    
    mutating func remove(_ peripheral: CBPeripheral) -> V? {
        self.removeValue(forKey: peripheral.identifier.uuidString)
    }
    
    subscript(peripheral: CBPeripheral) -> V? {
        get { self[peripheral.identifier.uuidString] }
        set { self[peripheral.identifier.uuidString] = newValue }
    }
}

extension CBManagerState: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .resetting:    return "resetting"
        case .unsupported:  return "unsupported"
        case .unauthorized: return "unauthorized"
        case .poweredOn:    return "poweredOn"
        case .poweredOff:   return "poweredOff"
        case .unknown:      return "unknown"
        @unknown default:
            return "unknown sta"
        }
    }
}
