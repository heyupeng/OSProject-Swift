//
//  CodeField.swift
//  Sample-Swift
//
//  Created by Mac on 2021/5/10.
//

import UIKit

@IBDesignable

class CodeField: UITextField {
    
    var borderColor: UIColor = UIColor(red: 0.89, green: 0.93, blue: 1, alpha: 1)
    
    var borderInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    var borderSize: CGSize = CGSize.zero
    var borderSpacing = CGFloat(10.0)
    var isCustomattributedText = false
    
    var borderLayers: Array<CALayer> = []
    var textLayers: Array<CATextLayer> = []
    
    var customCursor: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: 18.5))
    
    @IBInspectable var digit:Int = 4 {
        didSet {
            addBorderLayers()
            addTextLayers()
        }
    }
    
    override var text: String? {
        didSet {
            updateAttributedText()
        }
    }
    override var attributedText: NSAttributedString? {
        didSet {
            if isCustomattributedText {
                self.isCustomattributedText = false
                return
            }
            updateAttributedText()
        }
    }
    
    override var frame: CGRect {
        didSet {
            updateBorderLayerRect()
            updateAttributedText()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateBorderLayerRect()
        updateLeftView()
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.textRect(forBounds: bounds)
        rect.origin.x += borderInsets.left
        rect.size.width -= borderInsets.left
        return rect
    }
    
    override func becomeFirstResponder() -> Bool {
        let become = super.becomeFirstResponder()
        updateCustomCursor()
        return become
    }
    
    override func resignFirstResponder() -> Bool {
        let resign = super.resignFirstResponder()
        updateCustomCursor()
        return resign
    }
    
    func setup() {
        self.addTextFieldDidChangeNotify()
        
        customCursor.isHidden = true
        customCursor.backgroundColor = tintColor
        customCursor.layer.zPosition = 10
        self.addSubview(customCursor)
        
        self.canvasView?.layer.isHidden = true
    }
    
    func addBorderLayers() {
        for border in borderLayers {
            border.removeFromSuperlayer()
        }
        let layers = NSMutableArray.init()
        for _ in 0..<digit {
            let layer = CALayer()
            layer.backgroundColor = borderColor.cgColor
            layer.cornerRadius = 8
            self.layer.addSublayer(layer)
            layers.add(layer)
        }
        borderLayers = layers as! Array
    }
    
    func updateBorderLayerRect() {
        var size = bounds.size
        var space:CGFloat = 10.0
        let totalSpace = space * (CGFloat(digit) - 1.0)
        let l = size.width - size.height * CGFloat(digit) - totalSpace
        if l > 0 {
            space = (size.width - size.height * CGFloat(digit)) / (CGFloat(digit) - 1.0)
            size.width = size.height
            
        }
        
        borderSize = size
        borderSpacing = space
        
        for layer in borderLayers {
            let index = borderLayers.firstIndex(of: layer)!
            layer.frame = CGRect(x: CGFloat(index) * (size.width + space), y: 0, width: size.width, height: size.height)
        }
        
        for layer in textLayers {
            let index = textLayers.firstIndex(of: layer)!
            let rect = CGRect(x: CGFloat(index) * (size.width + space), y: (size.height - layer.fontSize + font!.descender)*0.5, width: size.width, height: size.height)
            layer.frame = rect
        }
    }
    
    func addTextLayers() {
        // textlayers
        for border in textLayers {
            border.removeFromSuperlayer()
        }
        textLayers.removeAll()
        for _ in 0..<digit {
            let layer = CATextLayer()
            layer.contentsScale = UIScreen.main.scale;
            layer.alignmentMode = .center
            layer.truncationMode = .middle
            layer.font = font
            layer.fontSize = font!.pointSize
            
            layer.foregroundColor = textColor?.cgColor
            self.layer.addSublayer(layer)
            textLayers.append(layer)
        }
    }
    
    
    func updateLeftView() {
        guard self.borderLayers.first?.frame != nil else {
            return
        }
        var left = (self.borderLayers.first?.frame.midX)!
        let __text = (text as NSString?)!
        if __text.length > 0 {
            let ch = __text.substring(with: NSRange(location: 0, length: 1)) as NSString
            let size = ch.size(withAttributes: [.font: self.font!])
            left -= size.width * 0.5;
        }
        self.borderInsets.left = left
        
        self.leftViewMode = .always
        
        if leftView == nil {
            self.leftView = UIView.init(frame: CGRect(x: 0, y: 0, width: self.borderInsets.left, height: 2))
        }
        leftView?.frame = CGRect(x: 0, y: 0, width: self.borderInsets.left, height: 2)
    }
    
    func updateCustomCursor() {
        if isEditing, text != nil, text!.count < digit {
            customCursor.center = CGPoint(x: textLayers[text!.count].frame.midX, y: self.bounds.midY)
            customCursor.isHidden = false
        } else {
            customCursor.isHidden = true
        }
    }
    
    func updateAttributedText() {
        
        guard self.borderLayers.first?.frame.midX != nil else {
            return
        }
        
        var left = (self.borderLayers.first?.frame.midX)!
        let __text = text as! NSString
        
        let attr = NSMutableAttributedString.init(string: text!, attributes: [.font: self.font!, .foregroundColor: self.textColor!])
        var firstLength = CGFloat(0)
        var lastLength = CGFloat(0)
        
        for index in 0..<__text.length {
            let ch = __text.substring(with: NSRange(location: index, length: 1)) as NSString
            let size = ch.size(withAttributes: [.font: self.font!])
            lastLength = size.width;

            if index == 0 {
                left -= size.width * 0.5;
            }
            if index < digit - 1 {
                let v = borderSpacing + borderSize.width - lastLength * 0.5
                attr.addAttribute(NSAttributedString.Key.kern, value:v , range: NSRange(location: index, length: 1))
            }
            if index > 0 {
                let v = borderSpacing + borderSize.width - (lastLength + firstLength) * 0.5
                attr.addAttribute(NSAttributedString.Key.kern, value: v, range: NSRange(location: index - 1, length: 1))
            }
            firstLength = lastLength

        }
        
        for index in 0..<digit {
            let textLayer = textLayers[index]
            if (index >= __text.length) {
                textLayer.string = ""
                break
            }
            let ch = __text.substring(with: NSRange(location: index, length: 1)) as NSString
            textLayer.string = ch
        }
        
        updateCustomCursor()
        
        self.borderInsets.left = left
        
        
        self.isCustomattributedText = true
        self.attributedText = attr
        
        self.isCustomattributedText = true
        self.attributedText = attr
        
        self.updateLeftView()
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    func addTextFieldDidChangeNotify() {
        self.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    @objc func textFieldDidChange() {
        self.updateAttributedText()
    }
    
    // MARK: 内嵌视图
    var editor: UIView? {
        get {
            let clsName_TextFieldEditor = "UITextFieldEditor"
            let eidtor = self.subviews.filter { subview in
                let cls_name = NSStringFromClass(subview.classForCoder)
                if cls_name == clsName_TextFieldEditor {
                    return true
                }
                return false
            }.first
            return eidtor
        }
    }
    
    var canvasView: UIView? {
        get {
            let clsName_TextFieldCanvasView = "_UITextFieldCanvasView"
            var canvasView = subviews.filter { subview in
                let cls_name = NSStringFromClass(subview.classForCoder)
                if cls_name == clsName_TextFieldCanvasView {
                    return true
                }
                return false
            }.first
            if (canvasView != nil) { return canvasView }
            
            canvasView = self.editor?.subviews.filter { subview in
                let cls_name = NSStringFromClass(subview.classForCoder)
                if cls_name == clsName_TextFieldCanvasView {
                    return true
                }
                return false
            }.first
            
            return canvasView
        }
    }
    
}
