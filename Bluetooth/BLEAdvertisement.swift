//
//  BLEAdvertisement.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/9.
//

import Foundation

import CoreBluetooth

protocol BLEAccessibilityAdvertisement {
    var advertisement: BLEAdvertisement { get set }
    var RSSI: NSNumber { get set }
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
