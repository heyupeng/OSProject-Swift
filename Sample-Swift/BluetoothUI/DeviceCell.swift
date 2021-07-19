//
//  DeviceVC.swift
//  Sample-Swift
//
//  Created by Peng on 2022/9/7.
//

import Cocoa
import Foundation
import CoreBluetooth

class DeviceCell: NSTableCellView {
    
    var modelItem: DeviceCellModel! {
        willSet {
            removeRegiste()
        }
        didSet {
            updateSubviews()
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
        removeRegiste()
    }
    
    // Accessibility
    func setAccessibility(_ enabled: Bool) {
        accessoryButton.isHidden = !enabled
    }
    
    @IBAction func accessibilityActionForConnection(_ sender: NSButton) {
        if modelItem == nil { return }
        self.accessibilityCallback?(self)
    }
    
    func updateSubviews() {
        if modelItem == nil { return }
        modelItem.cell = self
        textField?.stringValue = modelItem.item.title
        detailTextTF?.stringValue = modelItem.item.detailText
        
        rssiLabel.stringValue = modelItem.item.rssiText
        rssiLabel.textColor = modelItem.item.rssiColor
        self.setAccessibility(modelItem.item.connectable)
    }
    
    func removeRegiste() {
        if (modelItem != nil) {
            modelItem.cell = nil
        }
    }
}

extension DeviceCell {
    struct CellItem {
        var title: String = ""
        var subtitle: String = ""
        var detailText: String = ""
        
        var rssiText: String = ""
        var rssiColor: NSColor?
        var connectable: Bool = false
    }
}
