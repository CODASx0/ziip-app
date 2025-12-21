//
//  ImageProcessor.swift
//  Ziip
//
//  Created by Kevin on 12/21/25.
//

import UIKit
import Photos
import PhotosUI
import SwiftUI

/// 图片处理服务
actor ImageProcessor {
    
    /// 将图片拉伸到目标宽高比
    /// - Parameters:
    ///   - image: 原始图片
    ///   - targetRatio: 目标宽高比
    /// - Returns: 拉伸后的图片
    nonisolated func stretchImage(_ image: UIImage, to targetRatio: AspectRatio) -> UIImage? {
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        let originalRatio = originalWidth / originalHeight
        let targetRatioValue = targetRatio.value
        
        var newWidth = originalWidth
        var newHeight = originalHeight
        
        // 计算新尺寸
        if originalRatio > targetRatioValue {
            // 原图更宽，需要在高度方向拉伸
            newHeight = originalWidth / targetRatioValue
        } else if originalRatio < targetRatioValue {
            // 原图更高，需要在宽度方向拉伸
            newWidth = originalHeight * targetRatioValue
        }
        // 如果比例相同则无需处理
        
        // 使用 UIGraphicsImageRenderer 重绘图片
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0 // 使用实际尺寸，避免缩放
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: newWidth, height: newHeight), format: format)
        let stretchedImage = renderer.image { context in
            image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        }
        
        return stretchedImage
    }
    
    /// 流式处理图片：逐张加载、处理、保存
    /// - Parameters:
    ///   - items: PhotosPickerItem 数组
    ///   - targetRatio: 目标宽高比
    ///   - progressHandler: 进度回调 (0.0 - 1.0)
    /// - Returns: 成功保存的图片数量
    func processAndSaveImages(
        _ items: [PhotosPickerItem],
        to targetRatio: AspectRatio,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async -> Int {
        let total = items.count
        var successCount = 0
        
        for (index, item) in items.enumerated() {
            // 使用 autoreleasepool 管理每张图的内存
            let saved = await processAndSaveSingleImage(item, to: targetRatio)
            if saved {
                successCount += 1
            }
            
            // 更新进度
            let progress = Double(index + 1) / Double(total)
            await MainActor.run {
                progressHandler(progress)
            }
        }
        
        return successCount
    }
    
    /// 处理并保存单张图片
    private func processAndSaveSingleImage(_ item: PhotosPickerItem, to targetRatio: AspectRatio) async -> Bool {
        // 加载原图
        guard let data = try? await item.loadTransferable(type: Data.self),
              let originalImage = UIImage(data: data) else {
            return false
        }
        
        // 处理图片
        guard let processedImage = stretchImage(originalImage, to: targetRatio) else {
            return false
        }
        
        // 保存到相册
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: processedImage)
            }
            return true
        } catch {
            print("保存图片失败: \(error)")
            return false
        }
    }
    
    /// 加载缩略图用于预览（低内存）
    nonisolated func loadThumbnail(from data: Data, maxSize: CGFloat = 200) -> UIImage? {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: maxSize,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}
