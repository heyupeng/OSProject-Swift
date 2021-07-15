//
//  UIimage+Extension.swift
//  Sample-Swift
//
//  Created by Peng on 2021/7/14.
//

import UIKit

extension UIImage {
    typealias DrawingAction = (_ ctx: CGContext)->Void
    
    /// 创建一张 RGBA 32-bit 的渲染图像，绘制内容交由 drawingAction。内部调用 `UIGraphicsBeginImageContextWithOptions`。
    /// - Parameters:
    ///   - size: 图像大小（单位为point， 而非像素pixel。）。
    ///   - opaque: 不透明布尔值。
    ///   - scale: 图像倍数。为0时，取值当前设备屏幕比例因子。
    ///   - drawingAction: 渲染绘图块。
    static func graphicsImageDrawer( size: CGSize, opaque: Bool, scale: CGFloat, drawingAction: DrawingAction) -> UIImage? {
        // 1. 开启画笔
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
        // 2. 绘制，交由外部
        drawingAction(UIGraphicsGetCurrentContext()!);
        // 3. 提取图像
        let output = UIGraphicsGetImageFromCurrentImageContext();
        // 4. 结束绘制
        UIGraphicsEndImageContext();
        return output;
    }
    
    
    /// 创建一张 RGBA 32-bit 的渲染图像，绘制内容交由 drawingAction
    /// - Parameters:
    ///   - size: 图像大小（单位为point， 而非像素pixel。）。
    ///   - drawingAction: 渲染绘图块。
    /// - Returns:
    static func draw(size: CGSize, drawingAction: DrawingAction) -> UIImage? {
        guard size.width > 0, size.height > 0 else {
            return nil
        }
        if #available(iOS 10.0, *) {
            let imageRender = UIGraphicsImageRenderer(size: size)
            return imageRender.image { imageRendererContext in
                drawingAction(imageRendererContext.cgContext)
            }
        }
        let scale = UIScreen.main.scale
        return self.graphicsImageDrawer(size: size, opaque: false, scale: scale, drawingAction: drawingAction)
    }
    
    static func thumbImage(path: String, size: CGSize, scale: CGFloat) -> UIImage {
        let url = URL(fileURLWithPath: path)
        
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions)
        
        let maxPixel = max(size.width, size.height) * scale
        let ThumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ] as CFDictionary
        
        let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource!, 0, ThumbnailOptions)
        return UIImage(cgImage: cgImage!, scale: scale, orientation: .up)
    }
}
