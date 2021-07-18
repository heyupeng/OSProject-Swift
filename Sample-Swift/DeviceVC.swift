//
//  DeviceVC.swift
//  Sample-Swift
//
//  Created by Peng on 2022/9/7.
//

import Cocoa
import Foundation
import CoreBluetooth


class DeviceVC: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {
    var bleManager: BLEManager!
    var device: BLEDevice!
    
    @IBOutlet weak var tableView: NSTableView!
    
    @IBOutlet weak var titleLabel: NSTextField!
    
    @IBOutlet weak var advLabel: NSTextField!
    
    @IBOutlet weak var connectButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.stringValue = device.peripheral.name ?? "N/A"
        
        tableView.delegate = self
        tableView.dataSource = self
        
        if device.advertisement.isConnectable == false {
            connectButton.isEnabled = false
        }
        device.observeDisconnected() { [unowned self] device in
            DispatchQueue.main.async {
                self.setConnectButton("Connect")
            }
        }  error: { [unowned self] error in
            DispatchQueue.main.async {
                self.setConnectButton("Connect")
            }
            self.alert(error)
        }
        
        self.setsAdvString()
        
    }
    
    func setsAdvString() {
        var advString = ""
        if let name = device.advertisement.localName {
            advString.append("LocalName: \(name)")
        }
        
        if advString.count > 0 { advString.append("\n") }
        advString.append("Connectable: \(device.advertisement.isConnectable)")
        
        if let date = device.advertisement.date {
            advString.append("\n\nTime: ")
            advString.append(date.description(with: .current))
        }
        
        if let txPower = device.advertisement.txPowerLevel {
            advString.append("\nTx Power Level: \(txPower) dBm")
        }
        
        if let value = device.advertisement.rxPrimaryPHY {
            advString.append("\nRx Primary PHY: \(value)")
        }
        
        if let value = device.advertisement.rxSecondaryPHY {
            advString.append("\nRx Secondary PHY: \(value)")
        }
        
        if let value = device.advertisement.manufacturerData {
            advString.append("\n\nManufacturerData: ")
            advString.append(value.hexString + "(\(value.count) bytes)")
        }
        
        if let services = device.advertisement.ServiceUUIDs, services.count > 0 {
            advString.append("\n \n" + "Service UUIDs")
            services.forEach { uuid in
                advString.append("\n" + uuid.description)
            }
        }
        
        if let serviceData = device.advertisement.serviceData, serviceData.count > 0 {
            advString.append("\n \n" + "Service Data")
            serviceData.forEach({ (key: CBUUID, value: Data) in
                advString.append("\n" + key.description)
                advString.append(": " + value.hexString + "(\(value.count) bytes)")
            })
        }
        
        advLabel.stringValue = advString
        advLabel.drawsBackground = true
        advLabel.backgroundColor = .white
    }
    
    func setConnectButton(_ title: String, enabled: Bool = true) {
        self.connectButton.title = title
        self.connectButton.isEnabled = enabled
    }
    
    func connect() {
        setConnectButton("Connecting", enabled: false)
        
        self.bleManager.connect(device) { [unowned self]bleManager, device in
            DispatchQueue.main.async {
                self.setConnectButton("Disconnect")
            }
            device.discoverServices(nil, {[unowned self] device in
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    func disconnect() {
        setConnectButton("Disconnecting", enabled: false)
        
        self.bleManager.disconnect(device)
//        {[weak self] bleManager,device in
//            DispatchQueue.main.async {
//                self?.setConnectButton("connect")
//            }
//        }
    }
    
    func alert(_ error: Error, message: String? = nil) {
        DispatchQueue.main.async {
            let alert = NSAlert(error: error)
            if message != nil { alert.messageText = message! }
            alert.runModal()
        }
    }
    
    @IBAction func connectAction(_ sender: NSButton) {
        if device.peripheral.state == .disconnected {
            self.connect()
        }
        else {
            disconnect()
        }
    }
    
    @IBAction func goback(_ sender: NSButton) {
        self.bleManager.disconnect(device, nil)
        self.dismiss(self)
    }
    
    var cellItems: [CellItem] = []
}

extension DeviceVC: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let services = device.peripheral.services, services.count > 0 else {
            return 0
        }
        var items: [CellItem] = []
        var idx: AttIndexPath = .init(x: -1, y: -1, z: -1)
        services.forEach { service in
            idx.x += 1
            items.append(CellItem(idx: idx, title: service.uuid.description))
            service.characteristics?.forEach({ characteristic in
                idx.y += 1
                items.append(CellItem(idx: idx, title: characteristic.uuid.description))
                characteristic.descriptors?.forEach({ descriptor in
                    idx.z += 1
                    items.append(CellItem(idx: idx, title: characteristic.uuid.description))
                })
                idx.z = -1
            })
            idx.y = -1
        }
        cellItems = items;
        return cellItems.count
    }
    
//    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
//        return device.peripheral.services?[row]
//    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let item = cellItems[row]
        let cellIdentifier = item.attributeLevel == .service ? "Cell0" : "Cell1"
        let cell = tableView .makeView(withIdentifier: NSUserInterfaceItemIdentifier(cellIdentifier), owner: nil) as? NSTableCellView
        
        let title = item.indentationPrefix + item.title
        cell?.textField?.stringValue = title
        
        if let cell = cell as? AttributeCell, item.attributeLevel > .service {
            cell.accessoryButton3.bezelColor = nil
            if item.level(is: .characteristic) {
                let characteristic = device.peripheral.characteristic(item.idx)
                
                cell.subtitleTF.stringValue = item.subtitle(for: device.peripheral)
                cell.detailTF.stringValue = item.detailText(for: device.peripheral)
                
                let isCanRead = characteristic?.properties.contains(.read)
                let isCanWrite = characteristic?.properties.contains(.write)
                cell.accessoryButton.isEnabled = isCanRead ?? false
                cell.accessoryButton2.isEnabled = isCanWrite ?? false
                
                if let isCanNotify = characteristic?.properties.contains(.notify), isCanNotify == true {
                    cell.accessoryButton3.isEnabled = true
                    if characteristic!.isNotifying { cell.accessoryButton3.bezelColor = .cyan }
                } else {
                    cell.accessoryButton3.isEnabled = false
                }
            } else {
                cell.subtitleTF.stringValue = item.subtitle(for: device.peripheral)
                cell.detailTF.stringValue = item.detailText(for: device.peripheral)
                
                cell.accessoryButton.isEnabled = true
                cell.accessoryButton2.isEnabled = false
            }
            
            cell.accessoryCallback = {[unowned self] sender, event in
                self.accessoryButtonTap(tableView: tableView, row: row, event: event)
            }
        }
        return cell
    }
//    func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell? {
//
//
//    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let item = cellItems[row]
        return item.level(is: .service) ? 40 : 100
    }
    
    func accessoryButtonTapForCharacteristic(tableView: NSTableView, row: Int, event: AttributeCell.Event) {
        let item = cellItems[row]
        guard item.level(is: .characteristic),  let characteristic = device.peripheral.characteristic(item.idx) else {
            return
        }
        let err: BTH.Callbacks.Error = { [unowned self] err in
                self.alert(err)
        }
        switch event {
        case .read:
            self.device.readValue(for: characteristic) { device in
                DispatchQueue.main.async {
                    self.tableView.reloadData(forRowIndexes: IndexSet([row]), columnIndexes: IndexSet([0]))
                }
            } error: { err($0) }
        case .notify:
            self.device.setNotifyValue(!characteristic.isNotifying, for: characteristic) { device in
                DispatchQueue.main.async {
                    self.tableView.reloadData(forRowIndexes: IndexSet([row]), columnIndexes: IndexSet([0]))
                }
            } error: { err($0) }
            break
        default: break
        }
    }
    
    func accessoryButtonTap(tableView: NSTableView, row: Int, event: AttributeCell.Event) {
        if device.peripheral.state != .connected {
            return
        }
        let item = cellItems[row]
        if item.level(is: .characteristic) {
            accessoryButtonTapForCharacteristic(tableView: tableView, row: row, event: event)
            return
        }

        let characteristic = device.peripheral.characteristic(item.idx)
        if item.level(is: .descriptor), let descriptor = characteristic?.descriptors?[item.idx.z] {
            self.device.readValue(for: descriptor) { device in
                DispatchQueue.main.async {
                    self.tableView.reloadData(forRowIndexes: IndexSet([row]), columnIndexes: IndexSet([0]))
                }
            } error: { [unowned self] err in
                self.alert(err)
            }
        } else {
            self.alert(BTH.Error(.descriptor, code: .invalidDescriptor), message: "The descriptor is nil.")
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else { return }
        print("TableView did select: \(tableView.selectedRow)")
        
        if device.peripheral.state != .connected {
            self.alert(BTH.Error(.peripheral, code: .peripheralDisconnected))
            return
        }
        let item = cellItems[tableView.selectedRow]
        if item.level(is: .service) {
            guard let service = device.peripheral.services?[item.idx.x] else {
                return
            }
            device.discoverCharacteristics(nil, for: service, { device in
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            })
        }
        else if item.level(is: .characteristic) {
            guard let ch = device.peripheral.characteristic(item.idx) else {
                return
            }
            device.discoverDescriptors(for: ch, { device in
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            })
        }
    }
}

typealias AttIndexPath = CBPeripheral.Vector

extension AttIndexPath {
    var attributeLevel: AttributeLevel {
        if x == -1 { return .none }
        if y == -1 { return .service }
        if z == -1 { return .characteristic }
        return .descriptor
    }
}

enum AttributeLevel: Int {
    case none = -1, service, characteristic, descriptor
}

extension AttributeLevel: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    static func > (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue > rhs.rawValue
    }
}

struct CellItem {
    var idx: AttIndexPath = AttIndexPath(x: -1, y: -1, z: -1)
    var title: String
    var subtitle: String = ""
}

extension CellItem {
    var attributeLevel: AttributeLevel { idx.attributeLevel }
    
    var indentationPrefix: String {
        switch attributeLevel {
        case .characteristic: return " | "
        case .descriptor: return " || "
        default: return ""
        }
    }
    
    func level(is level: AttributeLevel) -> Bool {
        attributeLevel == level
    }
    
    func attribute(for peripheral: CBPeripheral) -> CBAttribute? {
        switch attributeLevel {
        case .service:          return peripheral.service(idx)
        case .characteristic:   return peripheral.characteristic(idx)
        case .descriptor:       return peripheral.descriptor(idx)
        default: break
        }
        return nil
    }
    
    func subtitle(for peripheral: CBPeripheral) -> String {
        if attributeLevel > .none {
            let attribute = attribute(for: peripheral)
            return indentationPrefix + "UUID: " + (attribute?.uuid.uuidString ?? "<Nil>")
        }
        return ""
    }
    
    func detailText(for peripheral: CBPeripheral) -> String {
        let att = self.attribute(for: peripheral)
        if attributeLevel == .characteristic, level(is: .characteristic) {
            return detailText(for: att as? CBCharacteristic)
        }
        else if attributeLevel == .descriptor {
            return detailText(for: att as? CBDescriptor)
        }
        return ""
    }
    
    func detailText(for characteristic: CBCharacteristic?) -> String {
        let prefix = indentationPrefix
        var text = ""
        text += indentationPrefix
        text += "Properties: " + (characteristic?.properties.description ?? "NULL")
        let detailString = characteristic?.stringValue ?? "<Nil>"
        text += "\n" + prefix + "Value: " + detailString
        return text
    }
    
    func detailText(for attribute: CBDescriptor?) -> String {
        return indentationPrefix + "Value: " + "\(attribute?.value ?? "")"
    }
}
