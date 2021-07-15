//
//  AnimatedImageView.swift
//  Sample-Swift
//
//  Created by Peng on 2021/6/18.
//

import UIKit

class FrameImageGroup: NSObject {
    open private(set) var bundleName: String = ""
    open private(set) var imageName: String = ""
    
    // only-read config
    /// 帧数。
    open private(set) var frameCount: Int = 0
    /// 帧速率。默认 25，即25帧每秒。
    open private(set) var framePerSecond: Int = 25
    
    open private(set) var repeatRange: Range<Int>?
    open private(set) var frameImageNames: [String] = []
    
    public init(named name: String, bundleName: String) {
        super.init()
        self.imageName = name
        self.bundleName = bundleName
        
        setup()
    }
    
    var bundle: Bundle {
        if let bundlePath = Bundle.main.path(forResource: bundleName, ofType: "bundle") {
            return Bundle.init(path: bundlePath)!
        }
        return Bundle.main
    }
    
    var config: [String: Any]? {
        guard imageName.count > 0 else {
            return nil
        }
        let bundle = self.bundle
        
        let kFrameImageGroupInRoot = "Frame Image Group"
        if let rootPath = bundle.path(forResource: "Root", ofType: "plist"),
           let root = NSDictionary.init(contentsOfFile: rootPath),
           let FIGCEnv = root[kFrameImageGroupInRoot] as? [String: Any],
           let config = FIGCEnv[imageName] as? [String: Any]
        {
            return config
        }
        return [:]
    }
    
    var frameImageDuration: TimeInterval {
        return TimeInterval(self.frameCount) * (1.0/TimeInterval(framePerSecond))
    }
    
    var frameImages: [UIImage] {
        var images: [UIImage] = []
        let count = self.frameCount
        for index in 0..<count {
            let name = imageName + "_" + String(format: "%02d", index)
            let path = bundle.path(forResource: name, ofType: "png")
            if path == nil { continue }
            images.append(UIImage(contentsOfFile: path!)!)
        }
        return images
    }
    
    func setup() {
        if let cfg = self.config, cfg.count > 0 {
            
            self.setupWithConfig(config: cfg)
            self.loadFrameImageNames(bundle: self.bundle)
            
        } else {
            self.loadFrameImageNames(bundle: self.bundle)
            
            self.frameCount = self.frameImageNames.count
        }
    }
    
    func setupWithConfig(config cfg: [String: Any]) {
        if let count = cfg["count"] as? Int {
            self.frameCount = count
        }
        
        if let framePerSecond = cfg["framePerSecond"] as? Int {
            self.framePerSecond = framePerSecond
        }
        
        if let repeatRangeString = cfg["repeatRange"] as? String,
           let repeatRangeUnits = repeatRangeString.split(separator: ",") as? [String],
           repeatRangeUnits.count > 1,
           let lower = Int(repeatRangeUnits.first!),
           let upper = Int(repeatRangeUnits.last!)
        {
            let range = Range(uncheckedBounds: (lower: lower, upper: upper))
            self.repeatRange = range
        }
    }
    
    func loadFrameImageNames(bundle: Bundle) {
        let imageType = "png"
        let totalPaths = bundle.paths(forResourcesOfType: imageType, inDirectory: nil)
        
        var paths = totalPaths.filter { path in
            if let b = path.split(separator: "/").last?.hasPrefix(imageName) { return b }
            return false
        }
        paths = paths.map { path in
            let b = path.split(separator: "/").last
            return String(b!)
        }
        
        paths.sort()
        
        frameImageNames = paths
    }
    
    func frameImagePath(namedInBundle name: String) -> String {
        return self.bundle.bundlePath + "/" + name
    }
    
    func frameImage(with index: Int) -> UIImage? {
        if index >= 0 ,index < self.frameImageNames.count {
            let name = self.frameImageNames[index]
            let path = self.frameImagePath(namedInBundle: name)
            return UIImage(contentsOfFile: path)
        }
        return nil
    }
}

open class AnimatedImageView: UIImageView {
    var bundleName: String?
    var animatedName: String = "" {
        didSet {
            
        }
    }
    
    var frameCount: Int = 0
    var frameAutoreverse: Bool = false
    var frameSpeed: Int = 1
    /// 帧速率。默认 framePerSecond = 25，即25帧每秒。
    var framePerSecond: Int = 25
    /// 手柄。完成一个动画周期后被调用
    var handler: (()->Void)?
    
    /// 循环区域
    var repeatRange: Range<Int>?
    
    var animatedTimer: Timer? = nil
    var frameIndex: Int = 0
    
    private var currentFrame: UIImage?
    private var frameImages: [UIImage?] = []
    private var currentAnimatedRepeatCount: Int = 0
    
    open override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    open override func startAnimating() {
        if self.animationImages != nil {
            super.startAnimating()
            return
        }
        self.m_startAnimating()
    }
    
    open override func stopAnimating() {
        if self.animationImages != nil {
            super.stopAnimating()
            return
        }
        self.m_stopAnimating()
    }
    
//    open override var isAnimating: Bool {
//        if self.animationImages != nil {
//            return super.isAnimating
//        }
//        if let t = animatedTimer, t.isValid {
//            return true
//        } else {
//            return false
//        }
//    }
    func reset() {
        self.frameIndex = 0
    }
    
    func m_startAnimating() {
        let timeInterval = 1.0 / TimeInterval(framePerSecond)
        
        currentAnimatedRepeatCount = 0
        
        self.m_stopAnimating()
        
        animatedTimer = Timer(timeInterval: timeInterval, repeats: true) { timer in
            guard self.superview != nil else {
                self.m_stopAnimating()
                return
            }
            guard self.currentAnimatedRepeatCount < self.animationRepeatCount else {
                self.m_stopAnimating()
                return
            }
            
            self.updateCurrentFrame()
            
            self.frameIndex += self.frameSpeed
            
            var isFinishInALifeCycle = false
            
            if !self.frameAutoreverse {
                var endIndex = self.frameCount
                if let range = self.repeatRange,
                   range.endIndex < endIndex { endIndex = range.endIndex }
                
                if self.frameIndex >= endIndex {
                    isFinishInALifeCycle = true
                    self.frameIndex = 0
                    
                    if let range = self.repeatRange,
                       range.startIndex > 0 { self.frameIndex = range.startIndex }
                }
            } else {
                if self.frameIndex >= self.frameCount {
                    self.frameSpeed = -1
                }
                else if self.frameIndex == 0 {
                    self.frameSpeed = 1
                    isFinishInALifeCycle = true
                }
            }
            
            if isFinishInALifeCycle {
                self.currentAnimatedRepeatCount += 1
                self.handler?()
            }
        }
        RunLoop.main.add(animatedTimer!, forMode: .common)
    }
    
    func m_stopAnimating() {
        self.animatedTimer?.invalidate()
    }
    
    var bundle: Bundle {
        get {
            if let bundlePath = Bundle.main.path(forResource: bundleName, ofType: "bundle") {
                return Bundle.init(path: bundlePath)!
            }
            return Bundle.main
        }
    }
    
    func currentFramePath(__frameIndex: Int) -> String? {
        let name = animatedName + "_" + String(format: "%02d", __frameIndex)
        if let path = bundle.path(forResource: name, ofType: "png") {
            return path
        }
        let screenScale = Int(UIScreen.main.scale);
        if let path = bundle.path(forResource: name + "@\(screenScale)x", ofType: "png") {
            return path
        } else if screenScale == 2, let path = bundle.path(forResource: name + "@3x", ofType: "png") {
            return path
        } else if screenScale == 3, let path = bundle.path(forResource: name + "@2x", ofType: "png") {
            return path
        }
        return nil
    }
    
    func updateCurrentFrame() {
        if self.frameImages.count > self.frameCount, let img = self.frameImages[self.frameIndex], img.size.width != 0 {
//            self.image = img
//            return
        }
        
        let path = self.currentFramePath(__frameIndex: self.frameIndex)
        if path == nil {
            return
        }
        #if false
        /// iPhone 8: Memory [26.2, 31.5]
        let image = UIImage.thumbImage(path: path!, size: self.bounds.size, scale: UIScreen.main.scale)
        #else
        /// iPhone 8: Memory [31.2, 34.2]
        let image = UIImage(contentsOfFile: path!) // UIImage(named: name, in: bundle, compatibleWith: nil)
        #endif
//        self.frameImages.append(self.currentFrame)
        
        self.currentFrame = image
        self.image = self.currentFrame
    }
}
