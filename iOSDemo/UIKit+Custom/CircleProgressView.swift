//
//  CircleProgressView.swift
//  Sample-Swift
//
//  Created by Mac on 2021/5/17.
//

import UIKit

/// Path operations on the current graphics context
protocol UIBezierPathOperations {
    /// 奇偶规则填充剪辑。
    func addEOClip()
    /// 笔划剪裁。
    func addStrokedClip()
}

extension UIBezierPath: UIBezierPathOperations {
    public convenience init(roundIn rect: CGRect) {
        self.init()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.5
        addArc(withCenter: center, radius: radius, startAngle: .pi * -0.5, endAngle: .pi * (-0.5 + 2), clockwise: true)
    }
    
    public convenience init(roundIn rect: CGRect, startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool = true) {
        self.init()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.5
        addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
        
    }
    
    public func addEOClip() {
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        ctx.addPath(self.cgPath)
        ctx.clip(using: .evenOdd)
    }
    
    public func addStrokedClip() {
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        ctx.addPath(self.cgPath)
        ctx.setLineJoin(lineJoinStyle)
        ctx.setLineCap(lineCapStyle)
        ctx.setLineWidth(lineWidth)
        
        ctx.replacePathWithStrokedPath()
        ctx.clip()
    }
}

@IBDesignable
class CircleProgressView: UIView {
    
    @IBInspectable var progress: CGFloat {
        didSet {
            updateProgress()
        }
    }
    
    @IBInspectable var progressStyle: Int {
        didSet {
            updateProgressGradientLayer()
            updateProgress()
        }
    }
    
    /// 当 barHeight < 0, 取值`0.5*view。frame.height`
    @IBInspectable var barHeight: CGFloat {
        didSet {
            updateTrackImageView()
            updateProgressGradientLayer()
            
            updateProgress()
        }
    }
    
    @IBInspectable var showThumb: Bool {
        didSet {
            updateThumbImageView()
        }
    }
    
    var trackImageView: UIView! = UIView()
    var progressImageView: UIImageView! = UIImageView()
    var thumbImageView: UIImageView! = UIImageView()
    
//     lazy var backgroundImageView: UIImageView = {() -> UIImageView in
//        let bgImageView = UIImageView()
//        bgImageView.frame = self.bounds
//        self.addSubview(bgImageView)
//        self.sendSubviewToBack(bgImageView)
//        return bgImageView
//    }()
    
    override class var layerClass: AnyClass {
        get {
            return CAShapeLayer.classForCoder()
        }
    }
    
    required init?(coder: NSCoder) {
        progress = CGFloat(0)
        progressStyle = 0
        barHeight = 5.0
        showThumb = true
        
        super.init(coder: coder)
        setup()
    }
    
    override init(frame: CGRect) {
        progress = CGFloat(0)
        progressStyle = 0
        barHeight = 5.0
        showThumb = true
        
        super.init(frame: frame)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = self.bounds.width * 0.5
        
        updateTrackImageView()
        
        updateProgressGradientLayer()
        
        updateProgress()
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    func setup() {
        
        addSubview(trackImageView)
        addSubview(progressImageView)
        addSubview(thumbImageView)
        
        // shadowCode
        trackImageView.layer.shadowColor = UIColor(red: 0.85, green: 0.91, blue: 0.95, alpha: 1).cgColor
        trackImageView.layer.shadowOffset = CGSize(width: 0, height: 0)
        trackImageView.layer.shadowOpacity = 1
        trackImageView.layer.shadowRadius = barHeight
        
        progressImageView.frame = self.bounds
        progressImageView.layer.cornerRadius = progressImageView.frame.height * 0.5
        
        progressImageView.layer.shadowColor = UIColor(red: 0.36, green: 0.96, blue: 0.98, alpha: 0.5).cgColor
        progressImageView.layer.shadowOffset = CGSize(width: 0, height: 1.3)
        progressImageView.layer.shadowOpacity = 1
        progressImageView.layer.shadowRadius = barHeight
        
        updateTrackImageView()
        
        updateProgressGradientLayer()
        
        updateThumbImageView()
        
    }
    
    var barLineWidth: CGFloat {
        get {
            if barHeight < 0 {
                return frame.height * 0.5
            }
            return barHeight
        }
    }
    
    func updateTrackImageView() {
        trackImageView.frame = self.bounds
        trackImageView.layer.cornerRadius = trackImageView.frame.height * 0.5
        
        let color1 = UIColor(rgbValue: 0xE1ECF5)
        
        // fillCode
        let bglayer: CAShapeLayer = CAShapeLayer()
//        bglayer.backgroundColor = color1.cgColor
        bglayer.strokeColor = color1.cgColor
        bglayer.fillColor = UIColor.clear.cgColor
        
        bglayer.frame = trackImageView.bounds
        bglayer.cornerRadius = bglayer.frame.height * 0.5
        
        trackImageView.layer.sublayers?.first?.removeFromSuperlayer()
        trackImageView.layer.addSublayer(bglayer)
        
        let insetByX: CGFloat = self.barLineWidth * 0.5
        let rect = self.bounds.insetBy(dx: insetByX, dy: insetByX)
        let radius = rect.height * 0.5
        
        let path = UIBezierPath.init()
        path.addArc(withCenter: CGPoint(x: rect.midX, y: rect.midY), radius: radius, startAngle: -CGFloat.pi * 0.5, endAngle: -CGFloat.pi * 0.5 + CGFloat.pi * 2, clockwise: true)
        bglayer.path = path.cgPath
        
        bglayer.lineWidth = self.barLineWidth
    }
    
    func progressPath() -> UIBezierPath {
        let insetByX: CGFloat = self.barHeight * 0.5
        let rect = self.bounds.insetBy(dx: insetByX, dy: insetByX)
        let radius = rect.height * 0.5
        
        let path = UIBezierPath.init()
        path.addArc(withCenter: CGPoint(x: rect.midX, y: rect.midY), radius: radius, startAngle: -CGFloat.pi * 0.5, endAngle: -CGFloat.pi * 0.5 + CGFloat.pi * 2 * progress, clockwise: true)
        return path
    }
    
    func updateProgressView() {
        let gradientLayer = (progressImageView.layer.sublayers?.first) as? CAGradientLayer
        
        gradientLayer?.isHidden = false
        
        let bounds = progressImageView.bounds
        let image = UIImage.draw(size: bounds.size) { ctx in
            ctx.saveGState()
            
//            let path1 = UIBezierPath(roundIn: bounds)
//            ctx.addPath(path1.cgPath)
//            let path2 = UIBezierPath(roundIn: bounds.insetBy(dx: self.barHeight, dy: self.barHeight))
//            ctx.addPath(path2.cgPath)
//
//            ctx.clip(using: .evenOdd)
            
            let path = self.progressPath()
            path.lineJoinStyle = .bevel
            path.lineCapStyle = .round
            path.lineWidth = self.barLineWidth
            
            path.addStrokedClip()
            
            gradientLayer?.render(in: ctx)
            ctx.restoreGState()
        }
        progressImageView.image = image
        
        gradientLayer?.isHidden = true
    }
    
    func updateThumbImageView() {
        
        thumbImageView.isHidden = !showThumb
        
        let insetByX: CGFloat = barHeight * 0.5
        let rect = self.bounds.insetBy(dx: insetByX, dy: insetByX)
        let radius: CGFloat = rect.height * 0.5
        let angle = -Double.pi / 2 + Double.pi * 2  * Double(progress)
        
        var thumbRect = CGRect.zero
        thumbRect.size = CGSize(width: self.barHeight - 2, height: self.barHeight - 2)
        thumbRect.origin.x =  radius * CGFloat(cos(angle))
        thumbRect.origin.y =  radius * CGFloat(sin(angle))
        thumbRect.origin.x += rect.midX - thumbRect.width * 0.5
        thumbRect.origin.y += rect.midY - thumbRect.height * 0.5
        
        thumbImageView.frame = thumbRect
        thumbImageView.backgroundColor = UIColor.white
        thumbImageView.layer.cornerRadius = thumbRect.width * 0.5
    }
    
    func updateProgress() {
        updateProgressView()
        
        updateThumbImageView()
    }
    
    func updateProgressGradientLayer() {
        progressImageView.frame = self.bounds
        progressImageView.layer.cornerRadius = progressImageView.frame.height * 0.5
        
        var color1 = UIColor(rgbValue: 0x86FFEC)
        var color2 = UIColor(rgbValue: 0x74D8FA)
        var color3 = UIColor(rgbValue: 0x5DF6F9, alpha: 0.5)
        
        switch self.progressStyle {
        case 1:
            color1 = UIColor(rgbValue: 0x65E3FF)
            color2 = UIColor(rgbValue: 0x5BBEFF)
            color3 = UIColor(rgbValue: 0x5BBEFF, alpha: 0.5)
            break
        case 2:
            color1 = UIColor(rgbValue: 0xFDB3CE)
            color2 = UIColor(rgbValue: 0xF989B1)
            color3 = UIColor(rgbValue: 0xF989B1, alpha: 0.5)
            break
        default:
            break
        }
        
        progressImageView.layer.shadowColor = color3.cgColor
        
        var gradientLayer: CAGradientLayer? = (progressImageView.layer.sublayers?.first) as? CAGradientLayer
        if gradientLayer == nil {
            gradientLayer = CAGradientLayer()
            gradientLayer?.locations = [0, 1]
            gradientLayer?.startPoint = CGPoint(x: 0, y: 0.5)
            gradientLayer?.endPoint = CGPoint(x: 0.5, y: 0)
            
            progressImageView.layer.addSublayer(gradientLayer!)
        }
        
        gradientLayer?.frame = progressImageView.bounds
        gradientLayer?.cornerRadius = gradientLayer!.frame.height * 0.5
        gradientLayer?.colors = [color1.cgColor, color2.cgColor]
    }
    
    func circleProgressImage(bounds: CGRect) -> UIImage {
        return UIImage()
    }
    
    func update(progress: CGFloat, duration: CGFloat) {
        if duration <= 0 {
            self.progress = progress
            return
        }
        
        let n = Int(duration * 30)
        self.progress = 0
        
        var i = 0
        let timer = Timer.init(timeInterval: TimeInterval(duration/CGFloat(n)), repeats: true) { (timer) in
            i += 1
            DispatchQueue.main.async {
                self.progress = CGFloat(i) / CGFloat(n) * progress
                self.updateProgressView()
            }
            
            if i == n {
                timer.invalidate()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
    }
}
