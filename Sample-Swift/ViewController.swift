//
//  ViewController.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/9.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let effectView = NSVisualEffectView(frame: self.view.bounds)
        effectView.material = NSVisualEffectView.Material(rawValue: 3)!
        self.view.addSubview(effectView)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

