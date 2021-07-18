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

class ViewController: NSViewController {
    
    let bleManager = BLEManager()
    
    @IBOutlet weak var tableView: NSTableView!
    var datasource: Array<BLEDevice> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        test()
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
            self.datasource = bleManager.discovers
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

// MARK: Test
protocol Base {
    
}
/// Basic class
class GenericBase<T>: Base {
    typealias Element = T
}

extension ViewController {
    func test() {
//        testTypeConverted()
        
//        testclosure2pointer1()
        testMethodToClosure1()
    }
    
    func testCharacteristicProperties() {
        let p = CBCharacteristicProperties(rawValue: 40)
        let components = p.components
        print(components)
        let a1 = GenericBase<String>()
        let a2 = GenericBase<Int>()
        var values:[Base] = [a1]
        values.append(a2)
    }
    
    
    func testData() {
        var b: Int16 = 10
        
        let d1 = NSData(bytes: &b, length: 2)
        
        let d2 = withUnsafePointer(to: &b) { ptr in
            ptr.withMemoryRebound(to: Int8.self, capacity: 2) { ptr in
                Data(bytes: ptr, count: 2)
            }
        }
        
        let d3 = withUnsafeBytes(of: b) { rptr in
//            let ptr = rptr.bindMemory(to: Int8.self)
            return Data(buffer: rptr.bindMemory(to: Int8.self))
        }
        
        let d4 = withUnsafeBytes(of: b) { rptr in
            return Data(rptr)
        }
        
        print(d1);
        print(d2.hexString);
        print(d2.hexString);
        print(d2.hexString);
    }
}

class DeviceCell: NSTableCellView {
    
    var device: BLEDevice! {
        didSet {
            let item = CellItem(device: device)
            textField?.stringValue = item.title
            detailTextTF?.stringValue = item.detailText
            
            rssiLabel.stringValue = item.rssiText
            rssiLabel.textColor = item.rssiColor
            self.setAccessibility(device.advertisement.isConnectable)
        }
    }
    
    var accessibilityCallback: ((_ cell: DeviceCell)->Void)?
    
    var separatorInset: NSEdgeInsets = .init(top: 0, left: 2, bottom: 0, right: 2)
    lazy var lineView: NSView = NSView()
    
    @IBOutlet unowned(unsafe) open var subtitleTF: NSTextField?
    @IBOutlet unowned(unsafe) open var detailTextTF: NSTextField?
    
    @IBOutlet weak var rssiLabel: NSTextField!
    @IBOutlet weak var accessoryButton: NSButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layout() {
        super.layout()
        
        lineView.frame = separatorRectWithBounds(self.bounds, inset: separatorInset)
        lineView.layer?.backgroundColor = self.separatorColor().cgColor
        self.addSubview(lineView)
    }
    
    func separatorColor() -> NSColor {
        let white: CGFloat = isDark ? 0x32/255.0 : 0xe8/255.0
        let color = NSColor(white: white, alpha: 1)
        return color
    }
    
    private func separatorRectWithBounds(_ bounds: CGRect, inset: NSEdgeInsets = .init()) -> CGRect {
        var rect = bounds
        rect.size.height = 1
        rect.size.width -= inset.left + inset.right
        rect.origin.x = inset.left
        rect.origin.y = rect.height + 1
        return rect
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    // Accessibility
    func setAccessibility(_ enabled: Bool) {
        accessoryButton.isHidden = !enabled
    }
    
    @IBAction func accessibilityActionForConnection(_ sender: NSButton) {
        if device == nil { return }
        
        self.accessibilityCallback?(self)
    }
}

extension DeviceCell {
    struct CellItem {
        var title: String = ""
        var subtitle: String = ""
        var detailText: String = ""
        
        var rssiText: String = ""
        var rssiColor: NSColor?
    }
}

extension DeviceCell.CellItem {
    init(device: BLEDevice) {
        self.init()
        // title
        var title = ""
        title = "\(device.peripheral.name ?? "N/A")"
        if let companyName = device.advertisement.companyName {
            title += "  |  " + companyName
        }
        self.title = title
        
        // subtitle
        var subtitle = ""
        if let _ = device.advertisement.manufacturerData?.hexString {
            subtitle = "<\(device.advertisement.companyID?.hexString ?? "NIL")>"
            subtitle += "\(device.advertisement.specialData?.hexString ?? "")"
        }
        if subtitle.count > 0 {
            subtitle = "ManufacturerData:" + subtitle
        } else if let serviceData = device.advertisement.serviceData {
            subtitle = "SerivceData:" // serviceData[CBUUID(string: "FE95")]
            subtitle +=  (serviceData.first?.value as? Data)?.reversedHexString ?? ""
        }
        self.detailText = subtitle
        
        rssiText = "\(device.RSSI) dBm"
        /// color
        let rssiValue = device.RSSI.floatValue
        let g: Float = 0.6 + (75.0 + rssiValue)/75.0
        rssiColor = .init(red: CGFloat(1-g), green: CGFloat(g), blue: 0, alpha: 1)
    }
}

extension ViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return datasource.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return datasource[row]
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView .makeView(withIdentifier: NSUserInterfaceItemIdentifier("Cell1"), owner: nil) as? NSTableCellView
        
        let device = datasource[row]
        
        if let c = cell as? DeviceCell {
            c.device = device
            c.accessibilityCallback = { cell in
//            self.bleManager.connect(cell.device) { bleManager, device in
//                print("\(Thread.current)")
//                DispatchQueue.main.async {
//                    cell.layer?.backgroundColor = NSColor.systemBlue.cgColor
//                }
//            }
            }
        }
        
        return cell
    }
    
//    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
//        return 60
//    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let tableView = notification.object as? NSTableView
        print("TableView did select: \(String(describing: tableView?.selectedRow))")
        
        guard let row = tableView?.selectedRow, row >= 0 else {
            return
        }
        let vc = NSStoryboard.main?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("DeviceVC")) as? DeviceVC
        
        if let row = tableView?.selectedRow {
            vc?.bleManager = bleManager
            vc?.device = datasource[row]
        }
        
        self.presentAsSheet(vc!)
    }
    
}

