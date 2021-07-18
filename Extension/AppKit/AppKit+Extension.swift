//
//  AppKit+Extension.swift
//  Sample-Swift
//
//  Created by Peng on 2022/9/7.
//

import Cocoa
import Foundation

extension NSAppearance {
    public var isDark: Bool {
        return name == .darkAqua || name == .vibrantDark || name == .accessibilityHighContrastDarkAqua || name == .accessibilityHighContrastVibrantDark
    }
}

extension NSView {
    public var isDark: Bool {
        if let window = self.window {
            let appearance = window.effectiveAppearance
            return appearance.isDark
        }
        print("View's window is nil!")
        let appearance = NSApplication.shared.effectiveAppearance
        return appearance.isDark
    }
}
