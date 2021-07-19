//
//  BLEAdvertisement.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/9.
//

import Foundation

import CoreBluetooth

protocol BLEAccessibilityAdvertisement {
    var advert: BLEAdvertisement { get set }
    var rssiRecorder: BLERSSIRecorder { get }
}

enum BLEAdvertisementDataKey: String {
    case channel = "kCBAdvDataChannel"
    case rxPrimaryPHY = "kCBAdvDataRxPrimaryPHY"
    case rxSecondaryPHY = "kCBAdvDataRxSecondaryPHY"
    case timestamp = "kCBAdvDataTimestamp"
}

/// 广播信息/扫描响应数据
protocol BLEAdvertisementProtocol {
    var advertisementData: [String: Any] { get set}
    
    var isConnectable: Bool { get }
    
    var localName: String? { get }
    
    var manufacturerData: Data? { get }
    
    var serviceData: [CBUUID:Data]? { get }
    
    var ServiceUUIDs: [CBUUID]? { get }
    
    var solicitedServiceUUIDs: [CBUUID]? { get }
    
    var txPowerLevel: Int? { get }
    
    var channel: Int? { get }
    
    var timestamp: TimeInterval? { get }
    
    var rxPrimaryPHY: Int? { get }

    var rxSecondaryPHY: Int? { get }
}

extension BLEAdvertisementProtocol {
    var isConnectable: Bool {
        let value = advertisementData[CBAdvertisementDataIsConnectable] as? Bool
        return value ?? false
    }
    
    var localName: String? {
        let value = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        return value
    }
    
    var manufacturerData: Data? {
        let value = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        return value
    }
    
    var serviceData: [CBUUID:Data]? {
        let value = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID:Data]
        return value
    }
    
    var ServiceUUIDs: [CBUUID]? {
        let value = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
        return value
    }
    
    var solicitedServiceUUIDs: [CBUUID]? {
        let value = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
        return value
    }
    
    var txPowerLevel: Int? {
        return advertisementData[CBAdvertisementDataTxPowerLevelKey] as? Int
    }
    
    var channel: Int? {
        return value(for: .channel) as? Int
    }
    
    var timestamp: TimeInterval? {
        return value(for: .timestamp) as? TimeInterval
    }
    
    var rxPrimaryPHY: Int? {
        return value(for: .rxPrimaryPHY) as? Int
    }
    
    var rxSecondaryPHY: Int? {
        return value(for: .rxSecondaryPHY) as? Int
    }
    
    func value(for key: BLEAdvertisementDataKey) -> Any? {
        return advertisementData[key.rawValue]
    }
}

// extension
extension BLEAdvertisementProtocol {
    var companyID: Data? {
        guard let manufacturerData = self.manufacturerData, manufacturerData.count >= 2 else {
            return nil
        }
        return manufacturerData[0..<2]
    }
    
    var specialData: Data? {
        guard let manufacturerData = self.manufacturerData, manufacturerData.count > 2 else {
            return nil
        }
        return manufacturerData[2..<manufacturerData.count]
    }
    
    var date: Date? {
        guard let timestamp = self.timestamp else {
            return nil
        }
        return Date(timeIntervalSinceReferenceDate: TimeInterval(timestamp))
    }
    
    func serviceData(for UUIDString: String) -> Data? {
        return serviceData?[CBUUID(string: UUIDString)]
    }
}

extension BLEAdvertisementProtocol {
    var companyName: String? {
        if let companyIDData = companyID,
           let company = CompanyIdentfier(decimal: companyIDData.toUInt8()) {
            return company.company
        }
        return nil
    }
}

class BLEAdvertisement:NSObject, BLEAdvertisementProtocol {
    var advertisementData: [String : Any] = [:]
    
    convenience init(_ advertisementData: [String: Any]) {
        self.init()
        self.advertisementData = advertisementData
    }
}

class BLERSSIRecorder:NSObject {
    struct Item {
        let rssi: NSNumber;
        let time: timeb;
        
        init(_ rssi: NSNumber, time: timeb) {
            self.rssi = rssi
            self.time = time
        }
        
        var millSeconds: UInt64 {
            return UInt64(time.time) * 1000 + UInt64(time.millitm)
        }
    }
    
    typealias BLERSSIsubscriber = (_ sender: AnyObject, _ rssi: NSNumber) -> Void
    private var subscribers: [Int:BLERSSIsubscriber] = [:]
    
    var items: [Item] = []
    
    var rssi: NSNumber {
        return items.last?.rssi ?? 0
    }
    
    fileprivate func addRSSI(rssi: NSNumber) {
        var t: timeb = timeb()
        ftime(&t);
        let item =  Item(rssi, time: t)
        items.append(item)
    }
    
    fileprivate func subscribe(_ subscriber: @escaping (_ sender: AnyObject, _ rssi: NSNumber) -> Void) -> Int {
        let ID = self.subscribers.count + 1
        self.subscribers[ID] = subscriber
        return ID
    }
    
    fileprivate func removeSubscribe(_ ID: Int) {
        self.subscribers.removeValue(forKey: ID)
    }
    
    fileprivate func sendMsg(_ sender: AnyObject, _ rssi: NSNumber) {
        let subscribers = subscribers
        subscribers.forEach { (key, subscriber) in
            subscriber(sender, rssi)
        }
    }
}

extension BLEAccessibilityAdvertisement {
    var RSSI: NSNumber {
        self.rssiRecorder.rssi
    }
    
    func addRSSI(rssi: NSNumber) {
        self.rssiRecorder.addRSSI(rssi: rssi)
        sendMsg(self, rssi)
    }
    
    func subscribeRSSI(_ subscriber: @escaping (_ sender: AnyObject, _ rssi: NSNumber) -> Void) -> Int {
        return self.rssiRecorder.subscribe(subscriber)
    }
    
    func removeRSSISubscriber(_ ID: Int) {
        self.rssiRecorder.removeSubscribe(ID)
    }
    
    fileprivate func sendMsg(_ sender: Self, _ rssi: NSNumber) {
        self.rssiRecorder.sendMsg(sender as AnyObject, rssi)
    }
}
