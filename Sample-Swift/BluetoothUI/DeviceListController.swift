//
//  ViewController.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/9.
//

import Cocoa
import Foundation

import CoreBluetooth
import IOBluetooth
import IOBluetoothUI

class DeviceCellModel {
    private var rssiID = -1;
    
    var device: BLEDevice
    weak var cell: DeviceCell?
    
    init(_ device: BLEDevice, cell: DeviceCell? = nil) {
        self.device = device
        self.cell = cell
    }
    
    var item: DeviceCell.CellItem {
        return DeviceCell.CellItem(device: device)
    }
    
    func addRSSIRegister() {
        rssiID = device.subscribeRSSI {[unowned self] sender, rssi in
            DispatchQueue.main.async {
                self.cell?.modelItem = self
            }
        }
    }
    
    func cancelRSSIRegister() {
        device.removeRSSISubscriber(rssiID)
    }
}

extension DeviceCell.CellItem {
    init(device: BLEDevice) {
        self.init()
        
        // title
        var title = ""
        title = "\(device.peripheral.name ?? "N/A")"
        if let companyName = device.advert.companyName {
            title += "  |  " + companyName
        }
        self.title = title
        
        // subtitle
        var subtitle = ""
        if let _ = device.advert.manufacturerData?.hexString {
            subtitle = "<\(device.advert.companyID?.hexString ?? "NIL")>"
            subtitle += "\(device.advert.specialData?.hexString ?? "")"
        }
        if subtitle.count > 0 {
            subtitle = "ManufacturerData:" + subtitle
        } else if let serviceData = device.advert.serviceData {
            subtitle = "SerivceData:" // serviceData[CBUUID(string: "FE95")]
            subtitle +=  (serviceData.first?.value as? Data)?.reversedHexString ?? ""
        }
        self.detailText = subtitle
        
        rssiText = "\(device.RSSI) dBm"
        /// color
        let rssiValue = device.RSSI.floatValue
        let g: Float = 0.6 + (75.0 + rssiValue)/75.0
        rssiColor = .init(red: CGFloat(1-g), green: CGFloat(g), blue: 0, alpha: 1)
        
        connectable = device.advert.isConnectable
    }
}

class DeviceListController: NSViewController {
    
    let bleManager = BLEManager()
    
    @IBOutlet weak var tableView: NSTableView!
    var datasource: [DeviceCellModel] = []
    var mp: [UUID: Int] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func action(_ sender: Any) {
        NSLog("IOBluetoothDeviceSelectorController")
        let vc = IOBluetoothDeviceSelectorController.deviceSelector()
        vc?.beginSheetModal(for: self.view.window, modalDelegate: self, didEnd: nil, contextInfo: nil)
    }
    
    @IBAction func scanAction(_ sender: Any) {
        guard let sender = sender as? NSButton else {
            return
        }
        if bleManager.isScanning {
            sender.title = "Scan"
            bleManager.stopScan()
            return
        }
        sender.title = "Stop Scan"

        bleManager.scan { [unowned self] bleManager, device in
            let item = DeviceCellModel(device)
            item.addRSSIRegister()
            self.datasource.append(item)
            
            DispatchQueue.main.async {
                self.tableView.tableColumns[0].title = "Device (\(self.datasource.count))"
                self.tableView.reloadData()
            }
        } error: {[unowned sender] error in
            DispatchQueue.main.async {
                sender.title = "Scan"
            }
            alert(error)
        }
    }
}

func alert(_ error: Error, message: String? = nil) {
    DispatchQueue.main.async {
        let alert = NSAlert(error: error)
        if message != nil { alert.messageText = message! }
        alert.runModal()
    }
}

extension DeviceListController {
    
    func showDeviceDetail(_ device: BLEDevice) {
        let board = NSStoryboard.init(name: "DeviceList", bundle: nil)
        let vc = board.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("DeviceDetailDeviceController")) as? DeviceDetailController
        vc?.bleManager = bleManager
        vc?.device = device
        self.presentAsSheet(vc!)
    }
}

extension DeviceListController: NSOutlineViewDelegate, NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return datasource.count;
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        let item = datasource[index]
        return item
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        
        let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("Cell1"), owner: nil) as? DeviceCell
        if let cell = cell, let item = item as? DeviceCellModel {
            cell.modelItem = item
            cell.accessibilityCallback = { cell in
                self.showDeviceDetail(item.device)
                self.bleManager.connect(item.device)
            }
        }
        return cell
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        print(#function);
        return true
    }
    func outlineView(_ outlineView: NSOutlineView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        return proposedSelectionIndexes
    }
    func outlineView(_ outlineView: NSOutlineView, shouldSelect tableColumn: NSTableColumn?) -> Bool {
        print(#function);
        return true
    }
    func outlineView(_ outlineView: NSOutlineView, mouseDownInHeaderOf tableColumn: NSTableColumn) {
        print(#function);
    }
    func outlineView(_ outlineView: NSOutlineView, didClick tableColumn: NSTableColumn) {
        print(#function);
        let _ = outlineView.selectedColumn
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        print(#function)
        let outlineView = notification.object as! NSOutlineView
        let row = outlineView.selectedRow;
        self.showDeviceDetail(datasource[row].device);
    }
}

extension DeviceListController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return datasource.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return datasource[row]
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView .makeView(withIdentifier: NSUserInterfaceItemIdentifier("Cell1"), owner: nil) as? NSTableCellView
        
        let item = datasource[row]
        if let c = cell as? DeviceCell {
            c.modelItem = item
            c.accessibilityCallback = { cell in
            }
        }
        return cell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 50
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let tableView = notification.object as? NSTableView
        print("TableView did select: \(String(describing: tableView?.selectedRow))")
        
        guard let row = tableView?.selectedRow, row >= 0 else {
            return
        }
        if let row = tableView?.selectedRow {
            showDeviceDetail(datasource[row].device)
        }
    }
}

