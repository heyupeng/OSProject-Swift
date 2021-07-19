//
//  DeviceVC.swift
//  Sample-Swift
//
//  Created by Peng on 2022/9/7.
//

import Cocoa
import Foundation
import CoreBluetooth

class AttributeCell: NSTableCellView {
    enum identifier: String {
        case cell0 = "Cell0"
        case cell1 = "Cell1"
    }
    enum Event: Int {
        case none
        case read
        case write
        case notify
    }
    private(set) var event: Event = .none
    var accessoryCallback: ((_ sender: NSButton, _ event: Event) -> Void)?
    
    @IBOutlet weak var subtitleTF: NSTextField!
    @IBOutlet weak var textTF: NSTextField!
    @IBOutlet weak var detailTF: NSTextField!

    @IBOutlet weak var accessoryButton: NSButton!
    @IBOutlet weak var accessoryButton2: NSButton!
    @IBOutlet weak var accessoryButton3: NSButton!
    
    lazy var lineView: NSView = NSView()
    var separatorInset: NSEdgeInsets = .init(top: 0, left: 2, bottom: 0, right: 2)
    
    override func layout() {
        super.layout()
        
        lineView.frame = separatorRectWithBounds(self.bounds, inset: separatorInset)
        lineView.layer?.backgroundColor = .black.copy(alpha: 0.1)
        self.addSubview(lineView)
    }
    
    func accessoryEnabled(_ enabled: Bool) {
        self.accessoryButton2.isEnabled = enabled
    }
    
    // MARK: private
    private func separatorRectWithBounds(_ bounds: CGRect, inset: NSEdgeInsets = .init()) -> CGRect {
        var rect = bounds
        rect.size.height = 1
        rect.size.width -= inset.left + inset.right
        rect.origin.x = inset.left
        rect.origin.y = rect.height + 0.5
        return rect
    }
    
    // MARK: IBAction
    @IBAction private func accessoryAction(_ sender: NSButton) {
        event = .read
        accessoryCallback?(sender, .read)
    }
    
    @IBAction private func accessoryAction2(_ sender: NSButton) {
        event = .write
        accessoryCallback?(sender, .write)
    }
    
    @IBAction private func accessoryAction3(_ sender: NSButton) {
        event = .notify
        accessoryCallback?(sender, .notify)
    }
}
