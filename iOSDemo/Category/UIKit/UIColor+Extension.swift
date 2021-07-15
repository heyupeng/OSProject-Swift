//
//  Extension.swift
//  Sample-Swift
//
//  Created by Peng on 2021/7/14.
//

import UIKit

extension UIColor {
    
    public convenience init(rgbaValue: UInt32) {
        let r = CGFloat(((rgbaValue >> 24) & 0xFF)) / 255.0
        let g = CGFloat(((rgbaValue >> 16) & 0xFF)) / 255.0
        let b = CGFloat(((rgbaValue >> 8) & 0xFF)) / 255.0
        let a = CGFloat(((rgbaValue) & 0xFF)) / 255.0
        self.init(red: r, green: g, blue: b, alpha: a)
    }
    
    public convenience init(rgbValue: UInt, alpha: CGFloat = 1.0) {
        let r = CGFloat(((rgbValue >> 16) & 0xFF)) / 255.0
        let g = CGFloat(((rgbValue >> 8) & 0xFF)) / 255.0
        let b = CGFloat(((rgbValue >> 0) & 0xFF)) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
