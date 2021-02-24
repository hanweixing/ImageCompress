//
//  UIImage+Compress.swift
//  ScrollHero
//
//  Created by 韩卫星 on 2020/10/10.
//  Copyright © 2020 Percent. All rights reserved.
//

import Foundation

// 这个文件是对图片image的压缩，压缩算法使用的是LuBan压缩图片算法.

enum LKImageCompressWidthType {
    case small(minValue: CGFloat, maxValue: CGFloat)
    case middle(minValue: CGFloat, maxValue: CGFloat)
    case large(minValue: CGFloat, maxValue: CGFloat)
    case giant(minValue: CGFloat, maxValue: CGFloat)
    
    init(minV: CGFloat, maxV: CGFloat) {
        switch maxV {
        case 0..<1664:
            self = .small(minValue: minV, maxValue: maxV)
        case 1664..<4990:
            self = .middle(minValue: minV, maxValue: maxV)
        case 4990..<10240:
            self = .large(minValue: minV, maxValue: maxV)
        default:
            self = .giant(minValue: minV, maxValue: maxV)
        }
    }
    
    var size: (minV: CGFloat, maxV: CGFloat, size: CGFloat) {
        switch self {
        case .small(let minV, let maxV):
            return (minV: minV, maxV: maxV, size: max(60, minV * maxV / pow(1664, 2) * 150))
        case .middle(let minV, let maxV):
            let minV_value: CGFloat = CGFloat(Int(minV / 2))
            let maxV_value: CGFloat = CGFloat(Int(maxV / 2))
            let size_value: CGFloat = max(60, (minV_value * maxV_value) / pow(4990 / 2, 2) * 300)
            return (minV: minV_value, maxV: maxV_value, size: size_value)
        case .large(let minV, let maxV):
            let minV_value: CGFloat = CGFloat(Int(minV / 4))
            let maxV_value: CGFloat = CGFloat(Int(maxV / 4))
            let size_value: CGFloat = max(100, (minV_value * maxV_value) / pow(10240 / 4, 2) * 300)
            return (minV: minV_value, maxV: maxV_value, size: size_value)
        case .giant(let minV, let maxV):
            let multiple = ((maxV / 1280) == 0) ? 1 : (maxV / 1280)
            return (minV: minV / multiple, maxV: maxV / multiple, size: max(100, ((minV / multiple) * (maxV / multiple)) / pow(2560, 2) * 300))
        }
    }
}

enum LKImageCompressSizeType {
    case square(minValue: CGFloat, maxValue: CGFloat)
    case rectangle(minValue: CGFloat, maxValue: CGFloat)
    case other(minValue: CGFloat, maxValue: CGFloat)
    
    init?(size: CGSize) {
        let minV = min(size.width, size.height)
        let maxV = max(size.width, size.height)
        
        let ratio = minV / maxV
        
        if ratio > 0 && ratio <= 0.5 {
            // [1:1 ~ 9:16)
            self = .square(minValue: minV, maxValue: maxV)
        } else if ratio > 0.5 && ratio < 0.5625 {
            // [9:16 ~ 1:2)
            self = .other(minValue: minV, maxValue: maxV)
        } else if ratio >= 0.5625 && ratio <= 1 {
            // [1:2 ~ 1:∞)
            self = .rectangle(minValue: minV, maxValue: maxV)
        } else {
            return nil
        }
    }
    
    var size: (minV: CGFloat, maxV: CGFloat, size: CGFloat) {
        switch self {
        case .square(let minV, let maxV):
            let widthType = LKImageCompressWidthType.init(minV: minV, maxV: maxV)
            return widthType.size
        case .rectangle(let minV, let maxV):
            let multiple = ((maxV / 1280) == 0) ? 1 : (maxV / 1280)
            let size = max(100, ((minV / multiple) * (maxV / multiple)) / (1440 * 2560) * 400)
            return (minV: minV / multiple, maxV: maxV / multiple, size: size)
        case .other(let minV, let maxV):
            let ratio = minV / maxV
            let multiple = CGFloat(ceilf(Float(maxV / (1280 / ratio))))
            let size = max(100, ((minV / multiple) * (maxV / multiple)) / (1280 * (1280 / ratio)) * 500)
            return (minV: minV / multiple, maxV: maxV / multiple, size: size)
        }
    }
}

extension UIImage {
    public func lk_compressedImage() -> UIImage {
        if let type = LKImageCompressSizeType.init(size: self.size) {
            let compressSize = type.size.size
            let resizedImage = resizeTo(size: CGSize(width: type.size.minV, height: type.size.maxV))
            if let data = resizedImage.compressTo(size: compressSize) {
                return UIImage(data: data) ?? self
            }
        }
        return self
    }
    
    public func lk_compressedData() -> Data? {
        if let type = LKImageCompressSizeType.init(size: self.size) {
            let compressSize = type.size.size
            let resizedImage = resizeTo(size: CGSize(width: type.size.minV, height: type.size.maxV))
            if let data = resizedImage.compressTo(size: compressSize) {
                return data
            }
        }
        return nil
    }
    
    private func resizeTo(size: CGSize) -> UIImage {
        let ratio = self.size.height / self.size.width
        var factor: CGFloat = 1.0
        if ratio > 1 {
            factor = size.height / size.width
        } else {
            factor = size.width / size.height
        }
        let toSize = CGSize(width: self.size.width * factor, height: self.size.height * factor)
        
        UIGraphicsBeginImageContext(toSize)
        draw(in: CGRect.init(origin: CGPoint(x: 0, y: 0), size: toSize))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image ?? self
    }
    
    private func compressTo(size: CGFloat) -> Data? {
        var compression: CGFloat = 1.0
        let maxCompression: CGFloat = 0.1
        guard var data = self.jpegData(compressionQuality: compression) else {
            return nil
        }
        while CGFloat(data.count) > size && compression > maxCompression {
            compression -= 0.1
            if let temp = self.jpegData(compressionQuality: compression) {
                data = temp
            } else {
                return data
            }
        }
        return data
    }
}
