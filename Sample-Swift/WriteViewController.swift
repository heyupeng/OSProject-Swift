//
//  WriteViewController.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/9.
//

import Cocoa
import Foundation

class WriteViewController: NSViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func dismissAction(_ sender: NSButton) {
        self.dismiss(self)
    }
}
